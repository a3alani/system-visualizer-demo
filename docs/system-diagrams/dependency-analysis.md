graph TD
  subgraph "Dependency Analysis"
    subgraph "Most Referenced Models"
      Cases[Cases<br/>2 references]:::lowImpact
      Documents[Documents<br/>2 references]:::lowImpact
      Payments[Payments<br/>1 references]:::lowImpact
      Firm[Firm<br/>1 references]:::lowImpact
      Users[Users<br/>1 references]:::lowImpact
      Case[Case<br/>1 references]:::lowImpact
      User[User<br/>1 references]:::lowImpact
    end
    subgraph "Models with Most Dependencies"
      User[User<br/>4 deps]:::lowComplexity
      Firm[Firm<br/>3 deps]:::lowComplexity
      Document[Document<br/>2 deps]:::lowComplexity
    end
  end

  %% Key dependency relationships
  Firm --> Cases
  User --> Cases
  Firm --> Documents
  User --> Documents
  User --> Payments
  User --> Firm
  Firm --> Users

  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px
  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px
  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px
  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
