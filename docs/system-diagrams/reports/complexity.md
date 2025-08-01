graph TD
  subgraph "Complexity Analysis"
    subgraph "Top Complex Components"
      User[User<br/>Complexity: 8]:::lowComplexity
      Firm[Firm<br/>Complexity: 6]:::lowComplexity
      Document[Document<br/>Complexity: 4]:::lowComplexity
      UserService[UserService<br/>Complexity: 0]:::lowComplexity
    end
    subgraph "Models with Most Dependencies"
      User[User<br/>4 deps]:::lowComplexity
      Firm[Firm<br/>3 deps]:::lowComplexity
      Document[Document<br/>2 deps]:::lowComplexity
    end
  end


  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
