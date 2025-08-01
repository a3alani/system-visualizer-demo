graph TD
  subgraph "User Management"
    Firm[Firm<br/>3 assoc, 3 deps]:::lowComplexity
    User[User<br/>4 assoc, 4 deps]:::lowComplexity
  end

  subgraph "Documents"
    Document[Document<br/>2 assoc, 2 deps]:::lowComplexity
  end

  Document -.-> User

  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
