import axios from "axios";

export async function executeSQL(sql: string): Promise<any[]> {
  const res = await axios.post("/api/sql", { sql });
  return res.data.data;
}
