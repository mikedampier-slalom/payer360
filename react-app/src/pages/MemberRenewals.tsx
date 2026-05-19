import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, darkLayout } from '../lib/chartTheme';

export default function MemberRenewals() {
  const kpi = useSnowflakeQuery(
    'renewals-kpi',
    `SELECT
      ROUND(SUM(CASE WHEN RENEWAL_FLAG THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS RENEWAL_RATE,
      SUM(CASE WHEN LAPSE_FLAG THEN 1 ELSE 0 END) AS LAPSED,
      ROUND(AVG(TENURE_MONTHS),0) AS AVG_TENURE
    FROM PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS`
  );

  const monthly = useSnowflakeQuery(
    'renewals-monthly',
    `SELECT DATE_TRUNC('MONTH', EFFECTIVE_DATE) AS MONTH,
      ROUND(SUM(CASE WHEN RENEWAL_FLAG THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS RENEWAL_RATE
    FROM PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS
    GROUP BY 1 ORDER BY 1`
  );

  const byPlan = useSnowflakeQuery(
    'renewals-plan',
    `SELECT PLAN_TYPE,
      SUM(CASE WHEN RENEWAL_FLAG THEN 1 ELSE 0 END) AS RENEWED,
      SUM(CASE WHEN LAPSE_FLAG THEN 1 ELSE 0 END) AS LAPSED
    FROM PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS
    GROUP BY 1 ORDER BY 1`
  );

  const tenure = useSnowflakeQuery(
    'renewals-tenure',
    `SELECT CASE
      WHEN TENURE_MONTHS < 12 THEN '< 1yr'
      WHEN TENURE_MONTHS < 24 THEN '1-2yr'
      WHEN TENURE_MONTHS < 36 THEN '2-3yr'
      WHEN TENURE_MONTHS < 48 THEN '3-4yr'
      ELSE '4yr+' END AS BUCKET,
      COUNT(*) AS CNT
    FROM PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS
    GROUP BY 1 ORDER BY 1`
  );

  const churn = useSnowflakeQuery(
    'renewals-churn',
    `SELECT LINE_OF_BUSINESS,
      ROUND(SUM(CASE WHEN LAPSE_FLAG THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS CHURN_RATE
    FROM PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS
    GROUP BY 1 ORDER BY CHURN_RATE DESC`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Member Renewals</h1>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <KPICard title="Renewal Rate" value={`${kpi.data?.[0]?.RENEWAL_RATE}%`} tooltip="Percentage of eligible members who renewed their policy at term — a key indicator of member retention and satisfaction." />
        <KPICard title="Lapsed Members" value={kpi.data?.[0]?.LAPSED?.toLocaleString()} tooltip="Total number of members whose policies lapsed (terminated) — includes voluntary exits, non-payment, relocation, and employer changes." />
        <KPICard title="Avg Tenure" value={`${kpi.data?.[0]?.AVG_TENURE} mo`} tooltip="Average number of months members have been continuously enrolled — longer tenure indicates stronger member loyalty." />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="Renewal Rate Trend (%)">
          {monthly.data && monthly.data.length > 0 && (
            <Plot
              data={[{
                x: monthly.data.map((r: any) => r.MONTH),
                y: monthly.data.map((r: any) => r.RENEWAL_RATE),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'Renewal Rate %',
                line: { color: COLORS.primary, width: 2 },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Renewal Rate %' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Renewed vs Lapsed by Plan Type">
          {byPlan.data && byPlan.data.length > 0 && (
            <Plot
              data={[
                {
                  x: byPlan.data.map((r: any) => r.PLAN_TYPE),
                  y: byPlan.data.map((r: any) => r.RENEWED),
                  type: 'bar',
                  name: 'Renewed',
                  marker: { color: COLORS.success },
                },
                {
                  x: byPlan.data.map((r: any) => r.PLAN_TYPE),
                  y: byPlan.data.map((r: any) => r.LAPSED),
                  type: 'bar',
                  name: 'Lapsed',
                  marker: { color: COLORS.danger },
                },
              ]}
              layout={{ ...darkLayout, barmode: 'group', yaxis: { ...darkLayout.yaxis, title: 'Members' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Member Tenure Distribution">
          {tenure.data && tenure.data.length > 0 && (
            <Plot
              data={[{
                x: tenure.data.map((r: any) => r.BUCKET),
                y: tenure.data.map((r: any) => r.CNT),
                type: 'bar',
                marker: { color: COLORS.primary },
                text: tenure.data.map((r: any) => r.CNT?.toLocaleString()),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Members' } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Churn Rate by Line of Business">
          {churn.data && churn.data.length > 0 && (
            <Plot
              data={[{
                x: churn.data.map((r: any) => r.LINE_OF_BUSINESS),
                y: churn.data.map((r: any) => r.CHURN_RATE),
                type: 'bar',
                marker: { color: COLORS.danger },
                text: churn.data.map((r: any) => `${r.CHURN_RATE}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Churn Rate %' } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
