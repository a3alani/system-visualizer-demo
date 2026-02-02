graph TD
  subgraph "PR Impact Analysis"
    subgraph "Changed Files"
      app_models_user_rb[user.rb<br/>high impact]
      app_models_user_rb style="fill:#ff6666"
    end

    subgraph "Affected Models"
      User[User<br/>0 deps, 0 assoc]
    end

  end

  %% Direct file changes
  app_models_user_rb --> User
  %% Dependency relationships
