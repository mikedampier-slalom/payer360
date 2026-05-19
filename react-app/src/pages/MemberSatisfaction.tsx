import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, darkLayout } from '../lib/chartTheme';

export default function MemberSatisfaction() {
  const kpi = useSnowflakeQuery(
    'satisfaction-kpi',
    `SELECT
      ROUND(AVG(CASE WHEN NPS_CATEGORY='Promoter' THEN 1 ELSE 0 END)*100 - AVG(CASE WHEN NPS_CATEGORY='Detractor' THEN 1 ELSE 0 END)*100,0) AS NPS,
      ROUND(AVG(CASE WHEN NPS_CATEGORY='Promoter' THEN 1 ELSE 0 END)*100,1) AS PROMOTER_PCT,
      ROUND(AVG(CASE WHEN NPS_CATEGORY='Detractor' THEN 1 ELSE 0 END)*100,1) AS DETRACTOR_PCT,
      ROUND(AVG(SATISFACTION_SCORE),1) AS AVG_SAT,
      ROUND(SUM(CASE WHEN IS_GRIEVANCE THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS GRIEVANCE_RATE
    FROM PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION`
  );

  const npsTrend = useSnowflakeQuery(
    'satisfaction-nps-trend',
    `SELECT SURVEY_MONTH AS MONTH,
      ROUND(AVG(CASE WHEN NPS_CATEGORY='Promoter' THEN 1 ELSE 0 END)*100 - AVG(CASE WHEN NPS_CATEGORY='Detractor' THEN 1 ELSE 0 END)*100,0) AS NPS
    FROM PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION
    GROUP BY 1 ORDER BY 1`
  );

  const categoryDist = useSnowflakeQuery(
    'satisfaction-categories',
    `SELECT SURVEY_MONTH AS MONTH,
      SUM(CASE WHEN NPS_CATEGORY='Promoter' THEN 1 ELSE 0 END) AS PROMOTERS,
      SUM(CASE WHEN NPS_CATEGORY='Passive' THEN 1 ELSE 0 END) AS PASSIVES,
      SUM(CASE WHEN NPS_CATEGORY='Detractor' THEN 1 ELSE 0 END) AS DETRACTORS
    FROM PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION
    GROUP BY 1 ORDER BY 1`
  );

  const byTopic = useSnowflakeQuery(
    'satisfaction-topic',
    `SELECT TOPIC, ROUND(AVG(SATISFACTION_SCORE),1) AS AVG_SAT
    FROM PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION
    GROUP BY 1 ORDER BY AVG_SAT`
  );

  const grievance = useSnowflakeQuery(
    'satisfaction-grievance',
    `SELECT CASE
      WHEN RESOLUTION_DAYS <= 5 THEN '0-5d'
      WHEN RESOLUTION_DAYS <= 10 THEN '6-10d'
      WHEN RESOLUTION_DAYS <= 20 THEN '11-20d'
      WHEN RESOLUTION_DAYS <= 30 THEN '21-30d'
      ELSE '30d+' END AS BUCKET,
      COUNT(*) AS CNT
    FROM PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION
    WHERE IS_GRIEVANCE
    GROUP BY 1 ORDER BY 1`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Member Satisfaction</h1>

      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <KPICard title="NPS Score" value={`${kpi.data?.[0]?.NPS}`} tooltip="Net Promoter Score — calculated as (% Promoters) minus (% Detractors). Ranges from -100 to +100; above 0 is good, above 50 is excellent." />
        <KPICard title="Promoter %" value={`${kpi.data?.[0]?.PROMOTER_PCT}%`} tooltip="Percentage of members who scored 9-10 on the NPS question — these members are likely to recommend the plan to others." />
        <KPICard title="Detractor %" value={`${kpi.data?.[0]?.DETRACTOR_PCT}%`} tooltip="Percentage of members who scored 0-6 on the NPS question — these members are dissatisfied and may leave or discourage others." />
        <KPICard title="Avg Satisfaction" value={`${kpi.data?.[0]?.AVG_SAT}`} tooltip="Average satisfaction score on a 1-10 scale across all survey responses — measures overall member experience quality." />
        <KPICard title="Grievance Rate" value={`${kpi.data?.[0]?.GRIEVANCE_RATE}%`} tooltip="Percentage of surveyed members who also filed a formal grievance within 90 days — indicates serious service failures." />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="NPS Trend">
          {npsTrend.data && npsTrend.data.length > 0 && (
            <Plot
              data={[{
                x: npsTrend.data.map((r: any) => r.MONTH),
                y: npsTrend.data.map((r: any) => r.NPS),
                type: 'scatter',
                mode: 'lines+markers',
                name: 'NPS',
                line: { color: COLORS.primary, width: 2 },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'NPS' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="NPS Category Distribution by Month">
          {categoryDist.data && categoryDist.data.length > 0 && (
            <Plot
              data={[
                { x: categoryDist.data.map((r: any) => r.MONTH), y: categoryDist.data.map((r: any) => r.PROMOTERS), type: 'bar', name: 'Promoters', marker: { color: COLORS.success } },
                { x: categoryDist.data.map((r: any) => r.MONTH), y: categoryDist.data.map((r: any) => r.PASSIVES), type: 'bar', name: 'Passives', marker: { color: COLORS.warning } },
                { x: categoryDist.data.map((r: any) => r.MONTH), y: categoryDist.data.map((r: any) => r.DETRACTORS), type: 'bar', name: 'Detractors', marker: { color: COLORS.danger } },
              ]}
              layout={{ ...darkLayout, barmode: 'stack', yaxis: { ...darkLayout.yaxis, title: 'Respondents' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Avg Satisfaction by Topic">
          {byTopic.data && byTopic.data.length > 0 && (
            <Plot
              data={[{
                y: byTopic.data.map((r: any) => r.TOPIC),
                x: byTopic.data.map((r: any) => r.AVG_SAT),
                type: 'bar',
                orientation: 'h',
                marker: { color: COLORS.primary },
                text: byTopic.data.map((r: any) => `${r.AVG_SAT}`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, margin: { t: 10, b: 30, l: 180, r: 70 }, yaxis: { ...darkLayout.yaxis }, xaxis: { ...darkLayout.xaxis, title: 'Avg Score' } }}
              style={{ height: '380px' }}
            />
          )}
        </ChartCard>

        <ChartCard title="Grievance Resolution Time">
          {grievance.data && grievance.data.length > 0 && (
            <Plot
              data={[{
                x: grievance.data.map((r: any) => r.BUCKET),
                y: grievance.data.map((r: any) => r.CNT),
                type: 'bar',
                marker: { color: COLORS.warning },
                text: grievance.data.map((r: any) => r.CNT?.toLocaleString()),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Grievances' } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
