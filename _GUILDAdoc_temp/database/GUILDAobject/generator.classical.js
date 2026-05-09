const classData = {
  name: "generator.classical",
  description: "Classical synchronous generator model represented by a constant voltage behind a transient reactance.",
  properties: [
    { name: "x_d", type: "double", description: "Transient reactance of the generator." },
    { name: "H", type: "double", description: "Inertia constant." },
    { name: "D", type: "double", description: "Damping coefficient." }
  ],
  methods: [
    {
      name: "get_nx",
      description: "Returns the number of internal states for the generator.",
      syntax: "nx = obj.get_nx()",
      inputs: [],
      outputs: [
        { name: "nx", type: "integer", description: "Number of states (e.g., 2 for classical model)." }
      ]
    },
    {
      name: "get_dx",
      description: "Calculates the state derivatives (dx/dt) based on current state and inputs.",
      syntax: "dx = obj.get_dx(x, V, I)",
      inputs: [
        { name: "x", type: "vector", description: "Current state vector." },
        { name: "V", type: "complex", description: "Terminal voltage." }
      ],
      outputs: [
        { name: "dx", type: "vector", description: "State derivatives." }
      ]
    }
  ]
};