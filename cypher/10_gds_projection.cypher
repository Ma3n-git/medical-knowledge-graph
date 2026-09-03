// GDS projection for patient similarity and condition analysis.
// Run this after the graph has been loaded and GDS is installed.
CALL gds.graph.project(
  'patient-condition-graph',
  ['Patient', 'Condition'],
  {
    HAS_CONDITION: {orientation: 'UNDIRECTED'}
  }
)
YIELD graphName, nodeCount, relationshipCount;

CALL gds.graph.list('patient-condition-graph')
YIELD graphName, nodeCount, relationshipCount;