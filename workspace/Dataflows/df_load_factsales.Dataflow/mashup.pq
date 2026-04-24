section Section1;
shared FactSales = let
  Server   = Variable.Value("vl_sales_dtp.SqlServer"),
  Database = Variable.Value("vl_sales_dtp.SqlDatabase"),
  Source   = Sql.Database(Server, Database, [Query="SELECT * FROM dbo.FactSales"])
in
  Source;