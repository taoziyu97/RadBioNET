"""Regression checks for source identity, dose semantics and review gates."""
import tempfile
from pathlib import Path
import unittest

from .adjudicate import adjudicated, audit_sample
from .audit import exact_bounds, weighted_estimate
from .batch_qc import evidence_checks, profiles, publication_sample
from .build import DOSE_IN_TEXT, resolve
from .dose import parse_dose
from .pubmed import parse_articles


class SourceTests(unittest.TestCase):
    def test_own_doi_excludes_cited_doi(self):
        xml = """<PubmedArticleSet><PubmedArticle><MedlineCitation><PMID>1</PMID>
        <Article><ArticleTitle>Title</ArticleTitle></Article></MedlineCitation><PubmedData>
        <ArticleIdList><ArticleId IdType="doi">10.1234/article</ArticleId></ArticleIdList>
        <ReferenceList><Reference><ArticleIdList><ArticleId IdType="doi">10.1234/cited</ArticleId>
        </ArticleIdList></Reference></ReferenceList></PubmedData></PubmedArticle></PubmedArticleSet>"""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sample.xml"
            path.write_text(xml)
            self.assertEqual(list(parse_articles(path))[0]["AID"], ["10.1234/article [doi]"])

    def test_identity_conflict_and_doi_disambiguation(self):
        row = {"DOI": "10.1/a", "Title": "Example title", "PMID": ""}
        self.assertEqual(resolve(row, {"10.1/a": {"pmid:1", "pmid:2"}},
                                 {"example title": {"pmid:1"}}, {}), ("pmid:1", "doi_title_disambiguated"))
        self.assertEqual(resolve(row, {"10.1/a": {"pmid:2"}},
                                 {"example title": {"pmid:1"}}, {})[1], "conflicting_doi_title")


class DoseTests(unittest.TestCase):
    def test_fractionation_and_ambiguity(self):
        cases = [("3×8 Gy", (3, "8", "24")),
                 ("8 Gy × 3", (3, "8", "24")),
                 ("3 fractions of 8 Gy", (3, "8", "24")),
                 ("Total 60 Gy in 30 equal fractions", (30, "2", "60")),
                 ("8 Gy in 3 fractions", (3, "", ""))]
        for raw, expected in cases:
            with self.subTest(raw=raw):
                row = parse_dose(raw)
                self.assertEqual(tuple(row[key] for key in ("fraction_count", "per_fraction", "total")), expected)

    def test_dose_types_and_roles(self):
        self.assertEqual(parse_dose("250 cGy")["value"], "2.50")
        self.assertEqual(parse_dose("60 Gy(RBE)")["quantity_type"], "rbe_weighted")
        self.assertEqual(parse_dose("0–8 Gy")["upper"], "8")
        self.assertEqual(parse_dose("0, 2, 8 or 24 Gy")["values"], "0|2|8|24")
        self.assertEqual(parse_dose("median mean heart dose 1.25 Gy")["dose_role"], "organ_metric")
        self.assertEqual(parse_dose("0 Gy sham control")["dose_role"], "control")
        self.assertEqual(parse_dose("1 Gy/min")["parse_status"], "unparsed")
        self.assertEqual(DOSE_IN_TEXT.findall("Doses were 0, 2, 8 or 24 Gy."), ["0, 2, 8 or 24 Gy"])
        self.assertEqual(DOSE_IN_TEXT.findall("A dose rate of 1 Gy/min was used."), [])


class ReviewTests(unittest.TestCase):
    def test_publication_audit_is_reproducible_with_a_short_final_batch(self):
        pmids = [str(i) for i in range(1001, 1408)]
        draws = publication_sample(pmids, 2026)
        self.assertEqual(draws, publication_sample(pmids[::-1], 2026))
        self.assertEqual([d["population_size"] for d in draws], [200, 200, 7])
        self.assertEqual([d["sample_size"] for d in draws], [10, 10, 7])
        self.assertEqual(len({p for d in draws for p in d["sampled_pmids"]}), 27)

    def test_irradiation_evidence_checks_are_field_specific(self):
        corpus = ("Ionizing radiation was applied. The photon group received 60 Gy. "
                  "The proton group received 50 Gy(RBE).")
        valid = dict(beam="photon", dose="60 Gy", beam_evidence="The photon group",
                     dose_evidence="The photon group received 60 Gy.")
        self.assertEqual(evidence_checks(corpus, [valid]), [])
        guessed = dict(valid, beam_evidence="Ionizing radiation")
        wrong_arm = dict(valid, dose="50 Gy(RBE)", dose_evidence="The proton group received 50 Gy(RBE).")
        self.assertEqual(
            [(f["field"], f["reason"]) for f in evidence_checks(corpus, [guessed, wrong_arm])],
            [("beam", "specific_beam_not_verified_by_quote"), ("dose", "dose_to_arm_link_requires_review")],
        )
        fields = profiles()["baseline"][2]["properties"]["records"]["items"]["properties"]
        self.assertNotIn("beam_evidence", fields)

    def test_one_review_and_disagreement_remain_pending(self):
        key = ("candidate", "1")
        accept = dict(decision="accept", codebook_version="1")
        reject = dict(decision="exclude", codebook_version="1")
        self.assertEqual(adjudicated(key, {"a": accept}, {}, ("decision",))[1], "pending_second_review")
        self.assertEqual(adjudicated(key, {"a": accept, "b": reject}, {}, ("decision",))[1], "awaiting_adjudication")
        self.assertEqual(adjudicated(key, {"a": accept, "b": reject}, {key: {"c": reject}},
                                     ("decision",))[0], reject)

    def test_finite_population_audit(self):
        self.assertEqual(exact_bounds(4, 4, 3, .05), (.75, .75))
        lo, hi = exact_bounds(1000, 20, 20, .05)
        self.assertTrue(.80 < lo < .90)
        self.assertEqual(hi, 1.0)
        a = weighted_estimate([(3, ["correct", "incorrect", "unverifiable"])], False)
        b = weighted_estimate([(3, ["correct", "incorrect", "unverifiable"])], True)
        self.assertAlmostEqual(a["estimate"], 1/3)
        self.assertAlmostEqual(b["estimate"], 2/3)

    def test_sampling_keeps_small_stratum(self):
        rows = [dict(relation_id=str(i), publication_id="p", particle_confirmed="Photon" if i else "Proton")
                for i in range(20)]
        pubs = {"p": {"source_membership": "general"}}
        sample = list(audit_sample(rows, pubs, 17, 5))
        self.assertEqual(len(sample), 5)
        self.assertEqual(next(x for x in sample if x["particle"] == "Proton")["inclusion_probability"], 1)
        self.assertEqual(sample, list(audit_sample(rows, pubs, 17, 5)))


if __name__ == "__main__":
    unittest.main()
