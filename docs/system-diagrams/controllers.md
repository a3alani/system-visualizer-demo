graph TD
  subgraph "Controllers"
    TestController[TestController]
  end

  TestController --> User
  TestController --> Document
  TestController --> UserService
