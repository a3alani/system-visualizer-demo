graph TD
  subgraph "Circular Dependency Analysis"
    NoCircular[No circular dependencies found]:::lowComplexity
    subgraph "High Complexity Areas"
    end
  end

  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
