# Example KG Queries

## 1. Find all radiosensitizing factors in glioma
SELECT * FROM triples
WHERE predicate = 'radiosensitizes' AND object = 'Glioma'
ORDER BY evidence_count DESC;

## 2. Find factors studied with proton therapy in pancreatic cancer
-- Step 1: factors studied with Proton
proton_factors = triples[
    (triples.predicate == 'studied_with_particle') &
    (triples.object == 'Proton')
]['subject']
-- Step 2: any direction with PDAC
result = triples[
    (triples.subject.isin(proton_factors)) &
    (triples.object == 'Pancreatic cancer')
]

## 3. "PARP1's neighborhood" — everything connected to PARP1
neighbors = triples[
    (triples.subject == 'PARP1') | (triples.object == 'PARP1')
]
# Returns all relationships involving PARP1: drugs targeting it,
# cancers where it sensitizes, cancers where it resists, factors it
# interacts with, modalities it's used in, etc.

## 4. Drug recommendations: drugs targeting factors that sensitize lung cancer
sensitizers_in_lung = triples[
    (triples.predicate == 'radiosensitizes') &
    (triples.object == 'Lung cancer')
]['subject']
drug_options = triples[
    (triples.predicate == 'targets') &
    (triples.object.isin(sensitizers_in_lung))
]

## 5. Find "research gaps" — factor × cancer × particle with NO triple
# Cross-product (Factor x Cancer x Particle), then anti-join against triples

## 6. Find "consensus" vs "controversy" pairs:
# Same factor → cancer → opposing directions (sensitizes AND resists)
