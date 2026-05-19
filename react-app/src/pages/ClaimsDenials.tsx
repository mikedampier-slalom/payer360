import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, COLOR_SEQ, darkLayout } from '../lib/chartTheme';

export default function ClaimsDenials() {
  const kpi = useSnowflakeQuery(
    'denials-kpi',
    `SELECT
      ROUND(SUM(CASE WHEN IS_DENIED THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS DENIAL_RATE,
      ROUND(SUM(CASE WHEN IS_DENIED THEN CHARGE_AMT ELSE 0 END)/1e6,1) AS DENIED_AMT,
      ROUND(SUM(CASE WHEN APPEAL_OUTCOME='WON' THEN 1 ELSE 0 END)*100.0/NULLIF(SUM(CASE WHEN IS_APPEALED THEN 1 ELSE 0 END),0),1) AS OVERTURN_RATE
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS`
  );

  const monthly = useSnowflakeQuery(
    'denials-monthly',
    `SELECT SERVICE_MONTH AS MONTH,
      ROUND(SUM(CASE WHEN IS_DENIED THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS DENIAL_RATE
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS
    GROUP BY 1 ORDER BY 1`
  );

  const byCategory = useSnowflakeQuery(
    'denials-category',
    `SELECT DENIAL_CATEGORY, COUNT(*) AS CNT, ROUND(SUM(CHARGE_AMT)/1e6,2) AS AMT
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS
    WHERE IS_DENIED
    GROUP BY 1 ORDER BY CNT DESC LIMIT 10`
  );

  const byLob = useSnowflakeQuery(
    'denials-lob',
    `SELECT LINE_OF_BUSINESS,
      ROUND(SUM(CASE WHEN IS_DENIED THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS DENIAL_RATE
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS
    GROUP BY 1 ORDER BY DENIAL_RATE DESC`
  );

  const appeals = useSnowflakeQuery(
    'denials-appeals',
    `SELECT APPEAL_OUTCOME, COUNT(*) AS CNT
    FROM PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS
    WHERE IS_APPEALED
    GROUP BY 1`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Claims Denials</h1>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <KPICard title="Denial Rate" value={`${kpi.data?.[0]?.DENIAL_RATE}%`} />
        <KPICard title="Denied Charges" value={`$${kpi.data?.[0]?.DENIED_AMT}M`} />
        <KPICard title="Appeal Overturn Rate" value={`${kpi.data?.[0]?.OVERTURN_RATE}%`} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="Denial Rate Trend (%)">
          {monthly.data && monthly.data.length > 0 && (
            <Plot
              data={[{
                x: monthly.data.map((r: any) => r.MONTH),
                y: monthly.data.map((r: any) => r.DENIAL_RATE),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'Denial Rate %',
                line: { color: COLORS.primary, width: 2 },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Denial Rate %' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Denials by Category (Top 10)">
          {byCategory.data && byCategory.data.length > 0 && (
            <Plot
              data={[{
                y: byCategory.data.map((r: any) => r.DENIAL_CATEGORY),
                x: byCategory.data.map((r: any) => r.CNT),
                type: 'bar',
                orientation: 'h',
                marker: { color: COLORS.primary },
                text: byCategory.data.map((r: any) => r.CNT?.toLocaleString()),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, margin: { t: 10, b: 30, l: 200, r: 70 }, yaxis: { ...darkLayout.yaxis, autorange: 'reversed' }, xaxis: { ...darkLayout.xaxis, title: 'Count' } }}
              style={{ height: '380px' }}
            />
          )}
        </ChartCard>

        <ChartCard title="Denial Rate by Line of Business">
          {byLob.data && byLob.data.length > 0 && (
            <Plot
              data={[{
                x: byLob.data.map((r: any) => r.LINE_OF_BUSINESS),
                y: byLob.data.map((r: any) => r.DENIAL_RATE),
                type: 'bar',
                marker: { color: COLOR_SEQ },
                text: byLob.data.map((r: any) => `${r.DENIAL_RATE}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Denial Rate %' } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Appeal Outcomes">
          {appeals.data && appeals.data.length > 0 && (
            <Plot
              data={[{
                values: appeals.data.map((r: any) => r.CNT),
                labels: appeals.data.map((r: any) => r.APPEAL_OUTCOME),
                type: 'pie',
                hole: 0.5,
                marker: { colors: [COLORS.success, COLORS.danger, COLORS.warning] },
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, showlegend: true, legend: { font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
