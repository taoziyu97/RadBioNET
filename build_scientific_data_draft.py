from pathlib import Path
import re

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


SOURCE = Path(
    "/Users/taozy/Nutstore Files/project/2025/放疗数据库/"
    "红皮杂志投稿材料准备/IJROBP_submission_0622/"
    "IJROBP_anonymized_manuscript.docx"
)
OUT_DIR = Path(
    "/Users/taozy/Nutstore Files/project/RadBioNET/Scientific_Data_submission"
)
OUTPUT = OUT_DIR / "RADBIONET_Scientific_Data_Data_Descriptor_draft.docx"


def set_cell_margins(cell, top=100, start=120, bottom=100, end=120):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcMar = tcPr.first_child_found_in("w:tcMar")
    if tcMar is None:
        tcMar = OxmlElement("w:tcMar")
        tcPr.append(tcMar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tcMar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tcMar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, width_dxa):
    tcPr = cell._tc.get_or_add_tcPr()
    tcW = tcPr.find(qn("w:tcW"))
    if tcW is None:
        tcW = OxmlElement("w:tcW")
        tcPr.append(tcW)
    tcW.set(qn("w:w"), str(width_dxa))
    tcW.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths):
    table.autofit = False
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    tblPr = table._tbl.tblPr
    tblW = tblPr.find(qn("w:tblW"))
    if tblW is None:
        tblW = OxmlElement("w:tblW")
        tblPr.append(tblW)
    tblW.set(qn("w:w"), str(sum(widths)))
    tblW.set(qn("w:type"), "dxa")
    tblInd = tblPr.find(qn("w:tblInd"))
    if tblInd is None:
        tblInd = OxmlElement("w:tblInd")
        tblPr.append(tblInd)
    tblInd.set(qn("w:w"), "120")
    tblInd.set(qn("w:type"), "dxa")
    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    for row in table.rows:
        for cell, width in zip(row.cells, widths):
            set_cell_width(cell, width)
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def shade_cell(cell, fill):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = tcPr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tcPr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_repeat_table_header(row):
    trPr = row._tr.get_or_add_trPr()
    tblHeader = OxmlElement("w:tblHeader")
    tblHeader.set(qn("w:val"), "true")
    trPr.append(tblHeader)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("Page ")
    run.font.name = "Times New Roman"
    run.font.size = Pt(9)
    fldChar1 = OxmlElement("w:fldChar")
    fldChar1.set(qn("w:fldCharType"), "begin")
    instrText = OxmlElement("w:instrText")
    instrText.set(qn("xml:space"), "preserve")
    instrText.text = "PAGE"
    fldChar2 = OxmlElement("w:fldChar")
    fldChar2.set(qn("w:fldCharType"), "end")
    run._r.append(fldChar1)
    run._r.append(instrText)
    run._r.append(fldChar2)


def set_font(run, size=12, bold=False, italic=False, color="000000"):
    run.font.name = "Times New Roman"
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), "Times New Roman")
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), "Times New Roman")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def add_body(doc, text, italic=False, keep_with_next=False):
    p = doc.add_paragraph(style="Normal")
    p.paragraph_format.keep_with_next = keep_with_next
    r = p.add_run(text)
    set_font(r, italic=italic)
    return p


def add_action(doc, text):
    p = doc.add_paragraph(style="Action Required")
    r = p.add_run("AUTHOR ACTION REQUIRED: " + text)
    set_font(r, size=10, bold=True, color="9B1C1C")
    return p


def add_heading(doc, text, level=1):
    return doc.add_paragraph(text, style=f"Heading {level}")


def extract_references(source_doc):
    texts = [p.text.strip() for p in source_doc.paragraphs if p.text.strip()]
    start = texts.index("References") + 1
    end = texts.index("Figure Captions")
    refs = []
    for text in texts[start:end]:
        if re.match(r"^\d+\.\s", text):
            refs.append(text)
    selected = refs[:16] + [refs[18]]
    selected[-1] = re.sub(r"^19\.", "17.", selected[-1])
    return selected


def configure_styles(doc):
    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    normal.font.size = Pt(12)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.DOUBLE
    normal.paragraph_format.widow_control = True

    for style_name, size, before, after in (
        ("Heading 1", 14, 14, 6),
        ("Heading 2", 12, 10, 4),
        ("Heading 3", 12, 8, 3),
    ):
        style = styles[style_name]
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
        style.paragraph_format.keep_with_next = True

    if "Action Required" not in styles:
        style = styles.add_style("Action Required", 1)
    else:
        style = styles["Action Required"]
    style.font.name = "Times New Roman"
    style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    style.font.size = Pt(10)
    style.font.bold = True
    style.font.color.rgb = RGBColor.from_string("9B1C1C")
    style.paragraph_format.space_before = Pt(4)
    style.paragraph_format.space_after = Pt(6)
    style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    style.paragraph_format.left_indent = Inches(0.18)
    style.paragraph_format.right_indent = Inches(0.18)


def build():
    source_doc = Document(SOURCE)
    references = extract_references(source_doc)

    doc = Document()
    configure_styles(doc)
    section = doc.sections[0]
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.49)
    section.footer_distance = Inches(0.49)
    add_page_number(section.footer.paragraphs[0])

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(12)
    title.paragraph_format.keep_with_next = True
    title_run = title.add_run(
        "A curated dataset of molecular factors in radiation response"
    )
    set_font(title_run, size=16, bold=True)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    subtitle.paragraph_format.space_after = Pt(16)
    sr = subtitle.add_run("Data Descriptor")
    set_font(sr, size=12, italic=True, color="555555")

    author_line = doc.add_paragraph()
    author_line.alignment = WD_ALIGN_PARAGRAPH.CENTER
    ar = author_line.add_run("[Author names and affiliations omitted from this anonymized draft]")
    set_font(ar, size=10, italic=True, color="555555")

    add_heading(doc, "Abstract", 1)
    abstract = (
        "Mechanistic radiation-biology evidence is dispersed across the literature and is "
        "difficult to reuse in a structured form. We compiled a literature-derived dataset "
        "of directional relationships between molecular or pharmacological factors and "
        "radiation responses across cancer types and irradiation modalities. The dataset "
        "contains more than 15,700 factor–source–particle relationships derived from 40,673 "
        "unique PubMed records published from 2000 to 2026. Each record links a factor to a "
        "controlled radiation-response direction and contextual metadata, including cancer "
        "type, experimental model, radiation dose, particle type, biological mechanism, "
        "evidence type and validation method. Relationships are graded using an explicit "
        "same-sentence evidence criterion, and radiation particles are recorded at category "
        "and specific-source levels without inference. The deposited tables, dictionaries "
        "and deterministic processing scripts are intended to support evidence retrieval, "
        "comparative radiation-biology analyses, hypothesis prioritization and independent "
        "reuse."
    )
    add_body(doc, abstract)

    add_heading(doc, "Background & Summary", 1)
    add_body(
        doc,
        "Radiotherapy is a principal modality of cancer treatment, used alone or in "
        "combination with surgery, systemic therapy and immunotherapy. Its effectiveness "
        "depends on maximizing tumour control while limiting normal-tissue toxicity. "
        "Molecular factors, epigenetic states, signalling pathways and pharmacological "
        "agents can alter radiosensitivity, radioresistance, immune effects and "
        "radiation-associated injury. However, the evidence needed to interpret these "
        "relationships remains distributed across a large and heterogeneous primary "
        "literature.¹–⁶",
    )
    add_body(
        doc,
        "Existing resources address complementary but incomplete parts of this problem. "
        "Clinical and imaging repositories aggregate treatment and outcome data, particle "
        "irradiation resources summarize cell-survival and relative biological effectiveness "
        "measurements, and radiogenomic initiatives examine associations between inherited "
        "variation and treatment outcomes. Other resources catalogue radiation-associated "
        "genes or gene-expression signatures. These resources do not consistently encode "
        "which factor changes radiation response, the reported direction of that effect, "
        "the cancer context, the radiation particle and the strength of the supporting "
        "literature evidence.⁷–¹⁶",
    )
    add_body(
        doc,
        "To address this gap, we assembled a structured, literature-derived dataset of "
        "directional factor–radiation relationships. The release was constructed from "
        "40,673 unique PubMed sources and contains more than 15,700 records spanning genes "
        "and proteins, pathways, drugs, kinases, DNA-damage markers, cytokines, immune "
        "factors and additional biological categories. Each relationship is traceable to "
        "its source record and is annotated with controlled direction labels, contextual "
        "metadata, radiation-particle information and an evidence grade.",
    )
    add_body(
        doc,
        "The dataset is designed for reuse in evidence retrieval, landscape analyses, "
        "particle-aware comparisons, knowledge-graph construction and hypothesis "
        "prioritization. A companion web interface, RADBIONET, supports interactive "
        "searching and visualization, but the reusable data files and processing code are "
        "deposited separately so that access does not depend on the continued operation of "
        "the website.",
    )

    add_heading(doc, "Methods", 1)
    add_heading(doc, "Source identification and input records", 2)
    add_body(
        doc,
        "PubMed was searched for publications in radiation oncology and radiation biology "
        "published from 2000 to 2026, using the complete search strategy provided in "
        "Supplementary Appendix A. Retrieved records were deduplicated to produce 40,673 "
        "unique sources. Titles and abstracts constituted the textual input used for "
        "structured extraction.",
    )
    add_action(
        doc,
        "Insert the exact final PubMed search date, complete reproducible search string, "
        "download date, PubMed query URL where available, and deduplication rules. Confirm "
        "whether any sources other than PubMed—including TCGA or CGGA—were used.",
    )

    add_heading(doc, "Structured relationship extraction", 2)
    add_body(
        doc,
        "For each eligible source, a structured record was created to represent a molecular "
        "or pharmacological factor and its reported radiation-response direction. Contextual "
        "fields included cancer type and subtype, species or source, experimental model, "
        "radiation dose, biological mechanism, clinical role, clinical outcome association, "
        "evidence type and validation method. Cancer type was assigned only when supported "
        "by the relevant context; cancers mentioned exclusively in introductory or "
        "comparative clauses were excluded. Radiation-dose extraction preserved reported "
        "fractionation.",
    )
    add_body(
        doc,
        "A curated factor dictionary organized the included entities into 20 biological "
        "categories. Reported effects were mapped to nine controlled labels: "
        "radiosensitization, radioresistance, antitumour immune effect, immunogenic cell "
        "death, immunosuppressive effect, radiation-toxicity factor, upregulation by "
        "radiation, downregulation by radiation and no observed change.",
    )
    add_action(
        doc,
        "Describe who performed extraction, whether extraction was manual, rule based or "
        "semi-automated, the software versions used, training and adjudication procedures, "
        "and the exact definitions for all 30 fields. Deposit a machine-readable data "
        "dictionary and controlled-vocabulary tables.",
    )

    add_heading(doc, "Evidence grading and record-level audit", 2)
    add_body(
        doc,
        "An assertion was graded as Strong when the factor and its direction appeared "
        "together in the same sentence and as Weak otherwise. Each unique combination of "
        "factor, direction and radiation particle was then audited across its supporting "
        "sources. Combinations were classified as Likely real, partially supported, Weak or "
        "Likely artifact according to the proportion of supporting sources meeting the "
        "Strong criterion. Combinations classified as Likely artifact were excluded from "
        "the released analysis set.",
    )
    add_action(
        doc,
        "Provide the numerical thresholds defining Likely real, partially supported, Weak "
        "and Likely artifact, and state whether excluded records are preserved in a separate "
        "file with exclusion reasons.",
    )

    add_heading(doc, "Radiation-particle classification", 2)
    add_body(
        doc,
        "Radiation particle was annotated at two levels. Category-level labels comprised "
        "Photon, Proton, Carbon ion, Heavy ion, Neutron, Electron, Alpha and Unspecified. "
        "Specific-level labels distinguished biologically different sources or ions, "
        "including X-rays, gamma rays, helium ions, carbon ions and iron ions. Each particle "
        "assignment was accompanied by an evidence grade of Direct, Title level, "
        "Contextual, Paper level, Multiparticle or Unspecified. Particle identity was not "
        "inferred when the source used only a generic radiation term; these records were "
        "labelled Unspecified. Clinical modality was stored separately.",
    )

    add_heading(doc, "Dataset generation and reproducibility", 2)
    add_body(
        doc,
        "The processing pipeline and downstream relationship tables were generated using "
        "deterministic, rule-based procedures. No stochastic large-language-model component "
        "was used, and missing fields were not imputed. The deposited scripts, dictionaries "
        "and configuration files are intended to reproduce the released tables from the "
        "documented input records.",
    )
    add_action(
        doc,
        "Add software names and versions, operating environment, execution instructions, "
        "checksums for input and output files, and a release/version identifier.",
    )

    add_heading(doc, "Data Records", 1)
    add_heading(doc, "Repository record", 2)
    add_body(
        doc,
        "The dataset, supporting metadata and processing code will be available from a "
        "formal public repository under a persistent identifier. The repository record "
        "should contain the complete relationship table, source metadata, field-level data "
        "dictionary, controlled vocabularies, factor dictionary, particle dictionary, "
        "quality-control outputs and reproducible analysis scripts.",
    )
    add_action(
        doc,
        "Deposit the final data package before revision or no later than the second review "
        "round, then replace this note with the repository name, DOI/accession, version, "
        "license and exact file/folder inventory. Reviewers must have anonymous download "
        "access at first submission.",
    )

    add_heading(doc, "Relationship table and contextual fields", 2)
    add_body(
        doc,
        "Each row of the principal relationship table represents a literature-supported "
        "factor–direction relationship in a defined context. Core fields identify the "
        "source publication, factor and factor category, controlled response direction, "
        "cancer type and subtype, species or source, experimental model, radiation dose, "
        "particle category and specific particle, biological mechanism, clinical role, "
        "clinical outcome association, evidence type, validation method and evidence grade. "
        "The deposited data dictionary should specify the data type, allowed values, missing "
        "value encoding, unit conventions and definition for every column.",
    )
    add_action(
        doc,
        "Confirm the final row count and Strong-tier count. The current manuscript contains "
        "conflicting values of 15,720 versus 15,730 total relationships and 7,750 versus "
        "7,751 Strong relationships.",
    )

    add_heading(doc, "Controlled vocabularies and dictionaries", 2)
    add_body(
        doc,
        "Supporting vocabulary files define factor categories, directional labels, "
        "radiation-particle labels, evidence grades and other controlled fields used in the "
        "relationship table. These files enable users to interpret categorical values and "
        "apply the same definitions in independent analyses.",
    )
    add_action(
        doc,
        "State whether factor, cancer, cell-line, drug and pathway names are mapped to "
        "community identifiers such as HGNC, UniProt, Disease Ontology/OncoTree, Cellosaurus, "
        "ChEBI/PubChem and Reactome/KEGG. Add mappings where feasible.",
    )

    add_heading(doc, "Web access", 2)
    add_body(
        doc,
        "An interactive web interface is available at https://www.radbionet.com for "
        "searching, filtering and visualizing the dataset. The website is a secondary access "
        "route; the citable repository files are the versioned record described in this "
        "Data Descriptor.",
    )

    add_heading(doc, "Data Overview", 1)
    add_body(
        doc,
        "The current release contains more than 15,700 factor–source–particle relationships "
        "across 20 biological categories. Approximately half meet the Strong same-sentence "
        "criterion. Genes and proteins constitute the largest category, followed by "
        "pathways, drugs and kinases. Among records with an explicitly assigned particle, "
        "photons are most frequent, followed by protons and carbon ions. Radiosensitization "
        "and radioresistance are the most frequently represented response directions, with "
        "additional records describing immune effects, toxicity and radiation-induced "
        "expression changes (Fig. 1).",
    )

    add_heading(doc, "Technical Validation", 1)
    add_heading(doc, "Evidence-tier precision audit", 2)
    add_body(
        doc,
        "To obtain a preliminary estimate of precision in the Strong tier, two reviewers "
        "independently examined 25 randomly selected Strong factor–direction pairs against "
        "their supporting source sentences. Disagreements were intended to be resolved by "
        "adjudication. This audit assesses whether the extracted factor, direction and "
        "context are supported by the cited text rather than merely co-occurring elsewhere "
        "in the abstract.",
    )
    add_action(
        doc,
        "Report the sampling seed and sampling frame, reviewer expertise, number of "
        "agreements and disagreements, adjudication procedure, precision with 95% confidence "
        "interval, and inter-rater agreement (for example Cohen's kappa). A sample of 25 is "
        "preliminary; expand the audit substantially and stratify it by direction, evidence "
        "tier, particle and factor type.",
    )

    add_heading(doc, "Temporal holdout validation", 2)
    add_body(
        doc,
        "As an indirect test of whether the structured directional relationships retained "
        "reproducible signal, a temporal holdout evaluation used records published through "
        "2023 to score factor–direction–cancer relationships absent from the training "
        "network. Candidate relationships were considered subsequently supported when first "
        "reported in records published from 2024 to 2026. Standard neighbourhood-based link "
        "prediction indices were calculated from the training network.¹⁷ The resource "
        "allocation index achieved an AUROC of 0.73; 32 of the top 100 ranked candidates "
        "were subsequently supported, corresponding to 7.6-fold enrichment over the 4.2% "
        "candidate prevalence (Fig. 2). This analysis evaluates the internal utility of the "
        "structured relationships but does not substitute for record-level accuracy "
        "assessment.",
    )
    add_action(
        doc,
        "Deposit the complete train/test split, candidate list, labels and executable "
        "validation script. Clarify how publication dates, duplicate reports and sources "
        "available online before formal publication were handled.",
    )

    add_heading(doc, "Internal consistency and completeness checks", 2)
    add_body(
        doc,
        "Technical validation should also document automated checks for duplicate source "
        "records, duplicate relationships, allowed categorical values, referential integrity "
        "between tables, radiation-dose formatting, missingness by field and traceability of "
        "each relationship to its source identifier. Results of these checks should be "
        "provided as a versioned quality-control report in the repository.",
    )
    add_action(
        doc,
        "Run and report the proposed checks. The current IJROBP manuscript does not provide "
        "their numerical results, so they have not been inferred here.",
    )

    add_heading(doc, "Usage Notes", 1)
    add_body(
        doc,
        "The evidence grades describe textual support under the stated curation rules; they "
        "are not direct measures of experimental quality, effect size or causal certainty. "
        "Users should retain source identifiers and evidence grades when aggregating or "
        "filtering relationships and should consult the underlying publications before "
        "drawing mechanistic or clinical conclusions.",
    )
    add_body(
        doc,
        "The current release does not resolve intervention polarity. For example, "
        "\"inhibition of factor X radiosensitizes\" and \"overexpression of factor X "
        "radiosensitizes\" may share the same response-direction label. Particle-specific "
        "evidence is comparatively sparse, and apparent differences between photon and "
        "particle irradiation may reflect different experimental manipulations, models or "
        "reporting patterns. The source corpus is restricted to titles and abstracts, and "
        "coverage of normal-tissue toxicity is less extensive than coverage of tumour-cell "
        "biology.",
    )
    add_body(
        doc,
        "Users can access the versioned files directly from the repository for reproducible "
        "analysis. The web interface provides convenient exploration but may reflect a newer "
        "continuously updated release; analyses should cite and record the repository "
        "version used.",
    )
    add_action(
        doc,
        "Confirm the redistribution rights for any stored source sentences or abstract text. "
        "If rights are not available, release publication identifiers and derived annotations "
        "without redistributing copyrighted full abstracts or substantial source text.",
    )

    add_heading(doc, "Data Availability", 1)
    add_body(
        doc,
        "[PENDING REPOSITORY DEPOSIT] The versioned dataset and supporting metadata will be "
        "available from [repository name] at [DOI/accession]. The interactive website is "
        "available at https://www.radbionet.com.",
    )

    add_heading(doc, "Code Availability", 1)
    add_body(
        doc,
        "[PENDING CODE DEPOSIT] The scripts, dictionaries, configuration files and validation "
        "workflows used to generate and check the released dataset will be available from "
        "[repository name] at [DOI/URL], under [software license].",
    )

    add_heading(doc, "References", 1)
    for ref in references:
        p = doc.add_paragraph(style="Normal")
        p.paragraph_format.first_line_indent = Inches(-0.25)
        p.paragraph_format.left_indent = Inches(0.25)
        p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
        p.paragraph_format.space_after = Pt(3)
        r = p.add_run(ref)
        set_font(r, size=10)

    add_heading(doc, "Acknowledgements", 1)
    add_body(doc, "[To be completed in the non-anonymized submission.]")

    add_heading(doc, "Author Contributions", 1)
    add_body(
        doc,
        "[To be completed using the journal's authorship requirements and, preferably, "
        "CRediT contribution roles.]",
    )

    add_heading(doc, "Competing Interests", 1)
    add_body(doc, "[To be completed for all authors.]")

    add_heading(doc, "Funding", 1)
    add_body(doc, "[List all funders and grant numbers, or state that no external funding was received.]")

    add_heading(doc, "Ethics Statement", 1)
    add_body(
        doc,
        "[Confirm before submission.] The work described in this manuscript uses published "
        "literature records and does not report newly collected data from human participants "
        "or animals. If individual-level cohort data such as TCGA or CGGA were included, add "
        "the applicable access, consent and ethics information.",
    )

    add_heading(doc, "Figure Captions", 1)
    add_body(
        doc,
        "Figure 1. Construction and content of the directional radiation-biology dataset. "
        "(a) Source identification, deduplication, structured extraction, normalization, "
        "evidence grading and generation of released relationship tables. (b) Distribution "
        "of records across factor categories. (c) Two-level classification by radiation "
        "particle, with broad categories and specific sources or ions. (d) Distribution of "
        "records across controlled radiation-response directions.",
    )
    add_body(
        doc,
        "Figure 2. Temporal holdout validation of structured directional relationships. "
        "(a) A network trained on factor–direction–cancer relationships reported through "
        "2023 was used to score candidate relationships absent from training and evaluated "
        "against relationships first reported from 2024 to 2026. (b) Precision among the "
        "top-ranked candidates. (c) Receiver-operating-characteristic curves for the four "
        "neighbourhood-based indices; resource allocation achieved an AUROC of 0.73 and "
        "7.6-fold enrichment among the top 100 candidates.",
    )
    add_action(
        doc,
        "Revise the actual figure files to match these captions. Remove the photon-to-particle "
        "biological discovery panels from the Data Descriptor or reserve them for a separate "
        "research article; Scientific Data limits descriptive analysis and does not publish "
        "a conventional Results/Discussion narrative in Data Descriptors.",
    )

    # Explicitly set all run fonts and black text where style inheritance may vary.
    for paragraph in doc.paragraphs:
        for run in paragraph.runs:
            if run.font.name is None:
                set_font(run)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
