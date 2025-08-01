graph TD
  subgraph "Database Impact"
    subgraph "Missing Indexes"
      Document_user_id[Document_user_id<br/>Consider adding index on user_id]
      Document_case_id[Document_case_id<br/>Consider adding index on case_id]
      User_firm_id[User_firm_id<br/>Consider adding index on firm_id]
    end
  end

