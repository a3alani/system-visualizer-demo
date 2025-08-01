graph TD
  subgraph "Enhanced PR Report"
    AIRisk["🤖 AI Risk Score: 34/100<br/>Level: Medium"]:::mediumRisk
    subgraph "Changed Files"
      app_controllers_test_controller_rb[test_controller.rb<br/>medium impact]:::mediumImpact
      app_models_document_rb[document.rb<br/>high impact]:::highImpact
      app_models_firm_rb[firm.rb<br/>high impact]:::highImpact
      app_models_user_rb[user.rb<br/>high impact]:::highImpact
      app_services_user_service_rb[user_service.rb<br/>medium impact]:::mediumImpact
      app_workers_email_worker_rb[email_worker.rb<br/>low impact]:::lowImpact
    end

    subgraph "Affected Models"
      Document[Document<br/>7 deps, 7 assoc]
      Firm[Firm<br/>7 deps, 7 assoc]
      User[User<br/>9 deps, 9 assoc]
    end

    subgraph "Affected Controllers"
      TestController[TestController<br/>3 deps, 10 actions]
    end

    subgraph "Affected Services"
      UserService[UserService<br/>4 deps]
    end

    subgraph "Affected Workers"
      EmailWorker[EmailWorker<br/>6 deps]
    end

  end

  %% Direct file changes
  app_controllers_test_controller_rb --> TestController
  app_models_document_rb --> Document
  app_models_firm_rb --> Firm
  app_models_user_rb --> User
  app_services_user_service_rb --> UserService
  app_workers_email_worker_rb --> EmailWorker
  %% Dependency relationships
  Document -.-> User
  Document -.-> Firm
  User -.-> Firm
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
