import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, darkLayout } from '../lib/chartTheme';

export default function CombinedRatio() {
  const kpi = useSnowflakeQuery(
    'combined-kpi',
    `SELECT
      ROUND(AVG(COMBINED_RATIO_PCT),1) AS COMBINED,
      ROUND(AVG(LOSS_RATIO_PCT),1) AS LOSS_RATIO,
      ROUND(AVG(EXPENSE_RATIO_PCT),1) AS EXPENSE_RATIO,
      ROUND(SUM(UNDERWRITING_RESULT)/1e6,1) AS UW_RESULT
    FROM PAYER360_CUR.FINANCIAL.MART_COMBINED_RATIO`
  );

  const quarterly = useSnowflakeQuery(
    'combined-quarterly',
    `SELECT QUARTER_LABEL,
      ROUND(AVG(COMBINED_RATIO_PCT),1) AS COMBINED,
      ROUND(AVG(LOSS_RATIO_PCT),1) AS LOSS,
      ROUND(AVG(EXPENSE_RATIO_PCT),1) AS EXPENSE
    FROM PAYER360_CUR.FINANCIAL.MART_COMBINED_RATIO
    GROUP BY 1, QUARTER_DATE ORDER BY QUARTER_DATE`
  );

  const byLob = useSnowflakeQuery(
    'combined-lob',
    `SELECT LOB_NAME,
      ROUND(AVG(COMBINED_RATIO_PCT),1) AS COMBINED
    FROM PAYER360_CUR.FINANCIAL.MART_COMBINED_RATIO
    GROUP BY 1 ORDER BY COMBINED DESC`
  );

  const uwResult = useSnowflakeQuery(
    'combined-uw',
    `SELECT QUARTER_LABEL,
      ROUND(SUM(UNDERWRITING_RESULT)/1e6,2) AS UW_RESULT
    FROM PAYER360_CUR.FINANCIAL.MART_COMBINED_RATIO
    GROUP BY 1, QUARTER_DATE ORDER BY QUARTER_DATE`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Combined Ratio</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <KPICard title="Combined Ratio" value={`${kpi.data?.[0]?.COMBINED}%`} />
        <KPICard title="Loss Ratio" value={`${kpi.data?.[0]?.LOSS_RATIO}%`} />
        <KPICard title="Expense Ratio" value={`${kpi.data?.[0]?.EXPENSE_RATIO}%`} />
        <KPICard title="UW Result" value={`$${kpi.data?.[0]?.UW_RESULT}M`} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="Combined Ratio Trend (Quarterly)">
          {quarterly.data && quarterly.data.length > 0 && (
            <Plot
              data={[{
                x: quarterly.data.map((r: any) => r.QUARTER_LABEL),
                y: quarterly.data.map((r: any) => r.COMBINED),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'Combined Ratio %',
                line: { color: COLORS.primary, width: 2 },
              }]}
              layout={{
                ...darkLayout,
                yaxis: { ...darkLayout.yaxis, title: 'Combined Ratio %' },
                shapes: [{
                  type: 'line',
                  x0: 0,
                  x1: 1,
                  xref: 'paper',
                  y0: 100,
                  y1: 100,
                  line: { color: COLORS.danger, width: 2, dash: 'dash' },
                }],
                legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } },
              }}
            />
          )}
        </ChartCard>

        <ChartCard title="Loss Ratio + Expense Ratio (Quarterly)">
          {quarterly.data && quarterly.data.length > 0 && (
            <Plot
              data={[
                { x: quarterly.data.map((r: any) => r.QUARTER_LABEL), y: quarterly.data.map((r: any) => r.LOSS), type: 'bar', name: 'Loss Ratio', marker: { color: COLORS.danger } },
                { x: quarterly.data.map((r: any) => r.QUARTER_LABEL), y: quarterly.data.map((r: any) => r.EXPENSE), type: 'bar', name: 'Expense Ratio', marker: { color: COLORS.warning } },
              ]}
              layout={{ ...darkLayout, barmode: 'stack', yaxis: { ...darkLayout.yaxis, title: 'Ratio %' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Combined Ratio by LOB">
          {byLob.data && byLob.data.length > 0 && (
            <Plot
              data={[{
                y: byLob.data.map((r: any) => r.LOB_NAME),
                x: byLob.data.map((r: any) => r.COMBINED),
                type: 'bar',
                orientation: 'h',
                marker: { color: byLob.data.map((r: any) => r.COMBINED > 100 ? COLORS.danger : COLORS.success) },
                text: byLob.data.map((r: any) => `${r.COMBINED}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, margin: { t: 10, b: 30, l: 180, r: 70 }, yaxis: { ...darkLayout.yaxis, autorange: 'reversed' }, xaxis: { ...darkLayout.xaxis, title: 'Combined Ratio %' } }}
              style={{ height: '380px' }}
            />
          )}
        </ChartCard>

        <ChartCard title="Underwriting Result by Quarter ($M)">
          {uwResult.data && uwResult.data.length > 0 && (
            <Plot
              data={[{
                x: uwResult.data.map((r: any) => r.QUARTER_LABEL),
                y: uwResult.data.map((r: any) => r.UW_RESULT),
                type: 'bar',
                marker: { color: uwResult.data.map((r: any) => r.UW_RESULT >= 0 ? COLORS.success : COLORS.danger) },
                text: uwResult.data.map((r: any) => `$${r.UW_RESULT}M`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'UW Result ($M)' } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
