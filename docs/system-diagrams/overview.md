graph TD
  subgraph "Rails Application Architecture"
    subgraph "User Management Models"
      Firm[Firm]
      User[User]
    end
    subgraph "Documents Models"
      Document[Document]
    end
    subgraph "Top Services by Dependencies"
      UserService[UserService<br/>0 deps]
    end
    subgraph "Top Controllers by Actions"
      TestController[TestController<br/>5 actions]
    end
  end

  %% Key architectural relationships
