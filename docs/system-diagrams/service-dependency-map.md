graph TD
  subgraph "Service Dependency Map"
    subgraph "User Management Services"
      UserService[UserService<br/>0 deps]:::lowComplexity
    end
  end


  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
