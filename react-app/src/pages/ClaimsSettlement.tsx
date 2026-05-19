import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, darkLayout } from '../lib/chartTheme';

export default function ClaimsSettlement() {
  const kpi = useSnowflakeQuery(
    'settlement-kpi',
    `SELECT
      ROUND(AVG(TOTAL_CYCLE_DAYS),1) AS AVG_DAYS,
      ROUND(SUM(CASE WHEN IS_CLEAN_CLAIM THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS CLEAN_RATE,
      ROUND(SUM(CASE WHEN IS_AUTO_ADJUDICATED THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS AUTO_RATE,
      SUM(CASE WHEN CLAIM_STATUS='PENDING' THEN 1 ELSE 0 END) AS PENDING
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT`
  );

  const monthly = useSnowflakeQuery(
    'settlement-monthly',
    `SELECT DATE_TRUNC('MONTH', RECEIVED_DATE) AS MONTH,
      ROUND(AVG(TOTAL_CYCLE_DAYS),1) AS AVG_DAYS
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT
    GROUP BY 1 ORDER BY 1`
  );

  const distribution = useSnowflakeQuery(
    'settlement-dist',
    `SELECT CASE
      WHEN DAYS_TO_ADJUDICATE <= 5 THEN '0-5d'
      WHEN DAYS_TO_ADJUDICATE <= 10 THEN '6-10d'
      WHEN DAYS_TO_ADJUDICATE <= 15 THEN '11-15d'
      WHEN DAYS_TO_ADJUDICATE <= 30 THEN '16-30d'
      ELSE '30d+' END AS BUCKET,
      COUNT(*) AS CNT
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT
    GROUP BY 1 ORDER BY 1`
  );

  const cleanByLob = useSnowflakeQuery(
    'settlement-clean',
    `SELECT LINE_OF_BUSINESS,
      ROUND(SUM(CASE WHEN IS_CLEAN_CLAIM THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS CLEAN_RATE
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT
    GROUP BY 1 ORDER BY CLEAN_RATE DESC`
  );

  const autoTrend = useSnowflakeQuery(
    'settlement-auto',
    `SELECT DATE_TRUNC('MONTH', RECEIVED_DATE) AS MONTH,
      ROUND(SUM(CASE WHEN IS_AUTO_ADJUDICATED THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS AUTO_RATE
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT
    GROUP BY 1 ORDER BY 1`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Claims Settlement</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <KPICard title="Avg Days to Settle" value={`${kpi.data?.[0]?.AVG_DAYS}`} />
        <KPICard title="Clean Claim Rate" value={`${kpi.data?.[0]?.CLEAN_RATE}%`} />
        <KPICard title="Auto-Adjudication Rate" value={`${kpi.data?.[0]?.AUTO_RATE}%`} />
        <KPICard title="Pending Claims" value={kpi.data?.[0]?.PENDING?.toLocaleString()} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="Avg Cycle Days Trend (Monthly)">
          {monthly.data && monthly.data.length > 0 && (
            <Plot
              data={[{
                x: monthly.data.map((r: any) => r.MONTH),
                y: monthly.data.map((r: any) => r.AVG_DAYS),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'Avg Days',
                line: { color: COLORS.primary, width: 2 },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Days' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Adjudication Days Distribution">
          {distribution.data && distribution.data.length > 0 && (
            <Plot
              data={[{
                x: distribution.data.map((r: any) => r.BUCKET),
                y: distribution.data.map((r: any) => r.CNT),
                type: 'bar',
                marker: { color: COLORS.primary },
                text: distribution.data.map((r: any) => r.CNT?.toLocaleString()),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Claims' } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Clean Claim Rate by LOB">
          {cleanByLob.data && cleanByLob.data.length > 0 && (
            <Plot
              data={[{
                x: cleanByLob.data.map((r: any) => r.LINE_OF_BUSINESS),
                y: cleanByLob.data.map((r: any) => r.CLEAN_RATE),
                type: 'bar',
                marker: { color: COLORS.success },
                text: cleanByLob.data.map((r: any) => `${r.CLEAN_RATE}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Clean Claim Rate %' } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Auto-Adjudication Rate Trend">
          {autoTrend.data && autoTrend.data.length > 0 && (
            <Plot
              data={[{
                x: autoTrend.data.map((r: any) => r.MONTH),
                y: autoTrend.data.map((r: any) => r.AUTO_RATE),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'Auto-Adj Rate %',
                line: { color: COLORS.success, width: 2 },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Auto-Adj Rate %' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
