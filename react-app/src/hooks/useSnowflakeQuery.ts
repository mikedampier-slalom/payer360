import { useQuery } from "@tanstack/react-query";
import { executeSQL } from "../lib/snowflake";

export function useSnowflakeQuery(key: string, sql: string, enabled = true) {
  return useQuery({
    queryKey: [key, sql],
    queryFn: () => executeSQL(sql),
    enabled,
    staleTime: 5 * 60 * 1000,
  });
}
