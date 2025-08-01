graph TD
  subgraph "Enhanced PR Report"
    AIRisk["🤖 AI Risk Score: 18/100<br/>Level: Low"]:::lowRisk
    subgraph "Changed Files"
      app_controllers_test_controller_rb[test_controller.rb<br/>medium impact]:::mediumImpact
      app_models_user_rb[user.rb<br/>high impact]:::highImpact
      app_services_user_service_rb[user_service.rb<br/>medium impact]:::mediumImpact
    end

    subgraph "Affected Models"
      User[User<br/>6 deps, 6 assoc]
    end

    subgraph "Affected Controllers"
      TestController[TestController<br/>1 deps, 4 actions]
    end

    subgraph "Affected Services"
      UserService[UserService<br/>0 deps]
    end

  end

  %% Direct file changes
  app_controllers_test_controller_rb --> TestController
  app_models_user_rb --> User
  app_services_user_service_rb --> UserService
  %% Dependency relationships
  TestController -.-> User

  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px
  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px
  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px
  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
  classDef criticalRisk fill:#cc0000,stroke:#990000,stroke-width:3px,color:#ffffff
  classDef highRisk fill:#ff3333,stroke:#cc0000,stroke-width:2px
  classDef mediumRisk fill:#ffaa66,stroke:#cc6600,stroke-width:2px
  classDef lowRisk fill:#66ff66,stroke:#00cc00,stroke-width:2px
