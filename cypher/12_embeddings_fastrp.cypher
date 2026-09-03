// FastRP embeddings for patient and condition nodes.
CALL gds.fastRP.mutate('patient-condition-graph', {
  nodeLabels: ['Patient', 'Condition'],
  embeddingDimension: 128,
  iterationWeights: [1.0, 1.0, 1.0, 1.0],
  normalizationStrength: 0.5,
  mutateProperty: 'fastrp_embedding'
})
YIELD nodePropertiesWritten, configuration;

MATCH (p:Patient)
WHERE p.fastrp_embedding IS NOT NULL
RETURN p.id AS patient_id, size(p.fastrp_embedding) AS embedding_dimension
LIMIT 10;