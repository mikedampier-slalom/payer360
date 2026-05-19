import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, darkLayout } from '../lib/chartTheme';

export default function MedicalLossRatio() {
  const kpi = useSnowflakeQuery(
    'mlr-kpi',
    `SELECT
      ROUND(AVG(MLR_PCT),1) AS MLR,
      ROUND(SUM(PREMIUM_EARNED)/1e6,1) AS PREMIUM,
      ROUND(SUM(INCURRED_CLAIMS)/1e6,1) AS CLAIMS,
      ROUND(SUM(QUALITY_IMPROVEMENT_EXPENSE)/1e6,1) AS QI,
      ROUND(AVG(ADMIN_RATIO_PCT),1) AS ADMIN
    FROM PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO`
  );

  const monthly = useSnowflakeQuery(
    'mlr-monthly',
    `SELECT PERIOD_DATE AS MONTH,
      ROUND(AVG(MLR_PCT),1) AS MLR
    FROM PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO
    GROUP BY 1 ORDER BY 1`
  );

  const byLob = useSnowflakeQuery(
    'mlr-lob',
    `SELECT LOB_NAME,
      ROUND(AVG(MLR_PCT),1) AS MLR,
      MAX(MLR_THRESHOLD)*100 AS THRESHOLD,
      CASE WHEN AVG(MLR_PCT) >= MAX(MLR_THRESHOLD)*100 THEN TRUE ELSE FALSE END AS IS_COMPLIANT
    FROM PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO
    GROUP BY 1 ORDER BY MLR DESC`
  );

  const stacked = useSnowflakeQuery(
    'mlr-stacked',
    `SELECT PERIOD_DATE AS MONTH,
      ROUND(SUM(PREMIUM_EARNED)/1e6,2) AS PREMIUM,
      ROUND(SUM(INCURRED_CLAIMS)/1e6,2) AS CLAIMS,
      ROUND(SUM(QUALITY_IMPROVEMENT_EXPENSE)/1e6,2) AS QI
    FROM PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO
    GROUP BY 1 ORDER BY 1`
  );

  const compliance = useSnowflakeQuery(
    'mlr-compliance',
    `SELECT
      SUM(CASE WHEN IS_COMPLIANT THEN 1 ELSE 0 END) AS COMPLIANT,
      SUM(CASE WHEN NOT IS_COMPLIANT THEN 1 ELSE 0 END) AS NON_COMPLIANT
    FROM (
      SELECT LOB_ID, BOOL_AND(IS_COMPLIANT) AS IS_COMPLIANT
      FROM PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO
      GROUP BY 1
    )`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Medical Loss Ratio</h1>

      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <KPICard title="Overall MLR" value={`${kpi.data?.[0]?.MLR}%`} tooltip="Medical Loss Ratio — percentage of premium revenue spent on claims and quality improvement. ACA requires 80% (individual/small group) or 85% (large group)." />
        <KPICard title="Premium Earned" value={`$${kpi.data?.[0]?.PREMIUM}M`} tooltip="Total premium revenue collected from members across all lines of business." />
        <KPICard title="Incurred Claims" value={`$${kpi.data?.[0]?.CLAIMS}M`} tooltip="Total medical claims costs paid to providers on behalf of members." />
        <KPICard title="Quality Spend" value={`$${kpi.data?.[0]?.QI}M`} tooltip="Spending on quality improvement activities (care coordination, disease management, health IT) that counts toward MLR numerator." />
        <KPICard title="Admin Ratio" value={`${kpi.data?.[0]?.ADMIN}%`} tooltip="Percentage of premium spent on administrative costs (salaries, marketing, overhead) — lower is better for MLR compliance." />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="MLR Trend by Month (%)">
          {monthly.data && monthly.data.length > 0 && (
            <Plot
              data={[
                {
                  x: monthly.data.map((r: any) => r.MONTH),
                  y: monthly.data.map((r: any) => r.MLR),
                  type: 'scatter',
                  mode: 'lines+markers',
                  name: 'MLR %',
                  line: { color: COLORS.primary, width: 2 },
                },
                {
                  x: monthly.data.map((r: any) => r.MONTH),
                  y: monthly.data.map(() => 80),
                  type: 'scatter',
                  mode: 'lines',
                  name: '80% Threshold (Large Group)',
                  line: { color: COLORS.warning, dash: 'dash', width: 1 },
                },
                {
                  x: monthly.data.map((r: any) => r.MONTH),
                  y: monthly.data.map(() => 85),
                  type: 'scatter',
                  mode: 'lines',
                  name: '85% Threshold (Individual/Small)',
                  line: { color: COLORS.danger, dash: 'dash', width: 1 },
                },
              ]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'MLR %' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="MLR by Line of Business">
          {byLob.data && byLob.data.length > 0 && (
            <Plot
              data={[{
                y: byLob.data.map((r: any) => r.LOB_NAME),
                x: byLob.data.map((r: any) => r.MLR),
                type: 'bar',
                orientation: 'h',
                marker: { color: byLob.data.map((r: any) => r.IS_COMPLIANT ? COLORS.success : COLORS.danger) },
                text: byLob.data.map((r: any) => `${r.MLR}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, margin: { t: 10, b: 30, l: 180, r: 70 }, yaxis: { ...darkLayout.yaxis, autorange: 'reversed' }, xaxis: { ...darkLayout.xaxis, title: 'MLR %' } }}
              style={{ height: '340px' }}
            />
          )}
        </ChartCard>

        <ChartCard title="Premium vs Claims vs QI Spend ($M)">
          {stacked.data && stacked.data.length > 0 && (
            <Plot
              data={[
                { x: stacked.data.map((r: any) => r.MONTH), y: stacked.data.map((r: any) => r.CLAIMS), type: 'scatter', mode: 'lines', fill: 'tozeroy', name: 'Claims', line: { color: COLORS.danger } },
                { x: stacked.data.map((r: any) => r.MONTH), y: stacked.data.map((r: any) => r.QI), type: 'scatter', mode: 'lines', fill: 'tozeroy', name: 'Quality Improvement', line: { color: COLORS.success } },
                { x: stacked.data.map((r: any) => r.MONTH), y: stacked.data.map((r: any) => r.PREMIUM), type: 'scatter', mode: 'lines', name: 'Premium Earned', line: { color: COLORS.primary, width: 2 } },
              ]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: '$M' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="LOB Compliance Status">
          {compliance.data && compliance.data.length > 0 && (
            <Plot
              data={[{
                values: [compliance.data[0]?.COMPLIANT || 0, compliance.data[0]?.NON_COMPLIANT || 0],
                labels: ['Compliant', 'Non-Compliant'],
                type: 'pie',
                hole: 0.5,
                marker: { colors: [COLORS.success, COLORS.danger] },
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
