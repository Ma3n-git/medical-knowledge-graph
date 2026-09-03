// Node similarity between patients sharing conditions.
CALL gds.nodeSimilarity.stream('patient-condition-graph', {
  nodeLabels: ['Patient'],
  relationshipTypes: ['HAS_CONDITION'],
  similarityMetric: 'JACCARD',
  topK: 20
})
YIELD node1, node2, similarity
RETURN gds.util.asNode(node1).id AS patient_1,
       gds.util.asNode(node2).id AS patient_2,
       similarity
ORDER BY similarity DESC;

// Remove the projection when analysis is complete.
// CALL gds.graph.drop('patient-condition-graph');