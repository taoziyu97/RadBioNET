"""Conservative parsing of complete dose expressions."""
import re
from decimal import Decimal

NUMBER = r"(?:\d+(?:\.\d+)?|\.\d+)"
UNIT = r"c?Gy(?:\s*\(\s*RBE\s*\))?"
D = rf"(?P<dose>{NUMBER})"
U = rf"(?P<unit>{UNIT})"
N = r"(?P<n>[1-9]\d*)"
FR = r"(?:fractions?|fx)"
FORMS = [
    ("fractionated", rf"{N}\s*[×xX*]\s*{D}\s*{U}"),
    ("fractionated", rf"{D}\s*{U}\s*[×xX*]\s*{N}(?:\s*{FR})?"),
    ("fractionated", rf"{N}\s*{FR}\s*(?:of|[×xX*])\s*{D}\s*{U}(?:\s*(?:each|per fraction))?"),
    ("fractionated", rf"{D}\s*{U}\s*(?:per fraction|/\s*{FR})\s*(?:[×xX*,]|for)\s*{N}(?:\s*{FR})?"),
    ("total_schedule", rf"(?:(?:a\s+)?total(?:\s+dose)?(?:\s+of)?\s+){D}\s*{U}\s*(?:in|/|over)\s*{N}\s*(?:equal\s*)?{FR}"),
    ("ambiguous_schedule", rf"{D}\s*{U}\s*(?:in|/|over|,)\s*{N}(?:\s*(?:equal\s*)?{FR})"),
    ("per_fraction", rf"{D}\s*{U}\s*(?:per fraction|/\s*{FR})"),
    ("range", rf"{D}\s*(?P<first_unit>{UNIT})?\s*(?:[-–—−]|to)\s*(?P<high>{NUMBER})\s*{U}"),
    ("list", rf"(?P<items>{NUMBER}(?:\s*,\s*{NUMBER})*\s*(?:,?\s+(?:or|and)|,)\s*{NUMBER})\s*{U}"),
    ("control", rf"{D}\s*{U}\s*(?:\(?\s*(?:sham(?:[- ]irradiated)?|unirradiated)(?:\s+control)?\s*\)?)"),
    ("single", rf"{D}\s*{U}"),
]
PATTERNS = [(kind, re.compile(pattern, re.I)) for kind, pattern in FORMS]
ORGAN = re.compile(r"\b(?:(median|mean|maximum|minimum)\s+)?(mean|maximum|minimum)\s+([\w -]{1,50}?)\s+dose\s*[:=]?\s*(?:of\s+)?(.+)", re.I)


def parse_dose(raw):
    fields = dict(parse_status="unparsed", quantity_type="", unit_raw="", unit_normalized="",
                  value="", lower="", upper="", values="", fraction_count=None,
                  per_fraction="", total="", dose_role="unresolved", organ="", metric="",
                  summary_statistic="", derived_field="")
    token = raw.strip()
    organ = ORGAN.fullmatch(token)
    if organ:
        fields.update(dose_role="organ_metric", summary_statistic=organ[1] or "",
                      metric=organ[2].lower(), organ=organ[3].strip())
        token = organ[4]
    for kind, pattern in PATTERNS:
        m = pattern.fullmatch(token)
        if not m:
            continue
        parts = m.groupdict()
        unit = parts["unit"]
        weighted = "rbe" in unit.lower()
        scale = Decimal("0.01") if unit.lower().startswith("c") else Decimal(1)

        def number(value):
            return Decimal(value) * scale

        def plain(value):
            return format(value, "f")

        fields.update(parse_status=kind, quantity_type="rbe_weighted" if weighted else "physical",
                      unit_raw=unit, unit_normalized="Gy(RBE)" if weighted else "Gy")
        if kind == "list":
            fields["values"] = "|".join(plain(number(x)) for x in re.findall(NUMBER, parts["items"]))
            return fields
        value = number(parts["dose"])
        if kind == "range":
            first_unit = parts["first_unit"]
            if first_unit and re.sub(r"\s", "", first_unit.lower()) != re.sub(r"\s", "", unit.lower()):
                fields["parse_status"] = "mixed_units_review"
            elif value > number(parts["high"]):
                fields["parse_status"] = "reversed_range_review"
            else:
                fields.update(lower=plain(value), upper=plain(number(parts["high"])))
            return fields
        fields["value"] = plain(value)
        if parts.get("n"):
            fields["fraction_count"] = int(parts["n"])
        if kind == "fractionated":
            fields.update(per_fraction=plain(value), total=plain(value * fields["fraction_count"]),
                          dose_role="fraction_schedule", derived_field="total")
        elif kind == "total_schedule":
            fields.update(total=plain(value), dose_role="fraction_schedule")
            if re.search(r"\bequal\b", token, re.I):
                fields.update(per_fraction=plain(value / fields["fraction_count"]),
                              derived_field="per_fraction")
        elif kind == "per_fraction":
            fields.update(per_fraction=plain(value), dose_role="per_fraction")
        elif kind == "control" and value == 0:
            fields["dose_role"] = "control"
        elif kind == "control":
            fields["parse_status"] = "control_conflict_review"
        return fields
    return fields
