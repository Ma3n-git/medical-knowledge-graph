// Louvain community detection on the patient-condition projection.
CALL gds.louvain.stream('patient-condition-graph', {
  nodeLabels: ['Patient', 'Condition'],
  relationshipTypes: ['HAS_CONDITION'],
  includeIntermediateCommunities: false
})
YIELD nodeId, communityId
RETURN labels(gds.util.asNode(nodeId)) AS node_labels,
       gds.util.asNode(nodeId).id AS node_id,
       communityId
ORDER BY communityId, node_id;