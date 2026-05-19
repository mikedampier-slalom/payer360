import Plot from '../components/Plot';
import KPICard from '../components/KPICard';
import { ChartCard } from '../components/ChartCard';
import { useSnowflakeQuery } from '../hooks/useSnowflakeQuery';
import { COLORS, COLOR_SEQ, darkLayout } from '../lib/chartTheme';

export default function ProviderNetwork() {
  const kpi = useSnowflakeQuery(
    'network-kpi',
    `SELECT
      COUNT(CASE WHEN IS_ACTIVE THEN 1 END) AS NETWORK_SIZE,
      ROUND(COUNT(CASE WHEN IS_TERMINATED THEN 1 END)*100.0/COUNT(*),1) AS TURNOVER_RATE,
      COUNT(CASE WHEN CONTRACT_START >= DATEADD(MONTH, -12, CURRENT_DATE()) THEN 1 END) AS NEW_PROVIDERS,
      ROUND(AVG(CONTRACT_YEARS),1) AS AVG_YEARS
    FROM PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK`
  );

  const networkSize = useSnowflakeQuery(
    'network-size',
    `SELECT DATE_TRUNC('QUARTER', CONTRACT_START) AS QTR,
      COUNT(*) AS PROVIDERS
    FROM PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK
    WHERE IS_ACTIVE
    GROUP BY 1 ORDER BY 1`
  );

  const turnover = useSnowflakeQuery(
    'network-turnover',
    `SELECT SPECIALTY,
      ROUND(COUNT(CASE WHEN IS_TERMINATED THEN 1 END)*100.0/COUNT(*),1) AS TURNOVER
    FROM PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK
    GROUP BY 1 ORDER BY TURNOVER DESC LIMIT 10`
  );

  const termReasons = useSnowflakeQuery(
    'network-term-reasons',
    `SELECT TERMINATION_REASON, COUNT(*) AS CNT
    FROM PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK
    WHERE IS_TERMINATED
    GROUP BY 1 ORDER BY CNT DESC`
  );

  const quality = useSnowflakeQuery(
    'network-quality',
    `SELECT CASE
      WHEN QUALITY_SCORE < 2.5 THEN 'Below 2.5'
      WHEN QUALITY_SCORE < 3.0 THEN '2.5-3.0'
      WHEN QUALITY_SCORE < 3.5 THEN '3.0-3.5'
      WHEN QUALITY_SCORE < 4.0 THEN '3.5-4.0'
      WHEN QUALITY_SCORE < 4.5 THEN '4.0-4.5'
      ELSE '4.5-5.0' END AS BUCKET,
      COUNT(*) AS CNT
    FROM PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK
    GROUP BY 1 ORDER BY 1`
  );

  if (kpi.isLoading) return <div className="text-gray-400 p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Provider Network</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <KPICard title="Network Size" value={kpi.data?.[0]?.NETWORK_SIZE?.toLocaleString()} tooltip="Total number of actively contracted providers in the network — includes physicians, specialists, and facilities." />
        <KPICard title="Turnover Rate" value={`${kpi.data?.[0]?.TURNOVER_RATE}%`} tooltip="Percentage of providers who terminated their contract — high turnover disrupts member access and care continuity." />
        <KPICard title="New Providers (12mo)" value={kpi.data?.[0]?.NEW_PROVIDERS?.toLocaleString()} tooltip="Number of new provider contracts signed in the last 12 months — indicates network growth and recruitment success." />
        <KPICard title="Avg Contract Years" value={`${kpi.data?.[0]?.AVG_YEARS}`} tooltip="Average duration of provider contracts in years — longer contracts signal network stability and provider satisfaction." />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard title="Network Size by Quarter">
          {networkSize.data && networkSize.data.length > 0 && (
            <Plot
              data={[{
                x: networkSize.data.map((r: any) => r.QTR),
                y: networkSize.data.map((r: any) => r.PROVIDERS),
                type: 'scatter',
                mode: 'lines',
                fill: 'tozeroy',
                name: 'Providers',
                line: { color: COLORS.primary },
                fillcolor: 'rgba(59, 130, 246, 0.3)',
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Providers' }, legend: { orientation: 'h', y: -0.2, font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Turnover Rate by Specialty (Top 10)">
          {turnover.data && turnover.data.length > 0 && (
            <Plot
              data={[{
                y: turnover.data.map((r: any) => r.SPECIALTY),
                x: turnover.data.map((r: any) => r.TURNOVER),
                type: 'bar',
                orientation: 'h',
                marker: { color: COLORS.danger },
                text: turnover.data.map((r: any) => `${r.TURNOVER}%`),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, margin: { t: 10, b: 30, l: 180, r: 70 }, yaxis: { ...darkLayout.yaxis, autorange: 'reversed' }, xaxis: { ...darkLayout.xaxis, title: 'Turnover %' } }}
              style={{ height: '380px' }}
            />
          )}
        </ChartCard>

        <ChartCard title="Termination Reasons">
          {termReasons.data && termReasons.data.length > 0 && (
            <Plot
              data={[{
                values: termReasons.data.map((r: any) => r.CNT),
                labels: termReasons.data.map((r: any) => r.TERMINATION_REASON),
                type: 'pie',
                hole: 0.5,
                marker: { colors: COLOR_SEQ },
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, showlegend: true, legend: { font: { color: '#a0a0a0' } } }}
            />
          )}
        </ChartCard>

        <ChartCard title="Provider Quality Score Distribution">
          {quality.data && quality.data.length > 0 && (
            <Plot
              data={[{
                x: quality.data.map((r: any) => r.BUCKET),
                y: quality.data.map((r: any) => r.CNT),
                type: 'bar',
                marker: { color: COLORS.primary },
                text: quality.data.map((r: any) => r.CNT?.toLocaleString()),
                textposition: 'outside',
                textfont: { color: '#e0e0e0' },
              }]}
              layout={{ ...darkLayout, yaxis: { ...darkLayout.yaxis, title: 'Providers' } }}
            />
          )}
        </ChartCard>
      </div>
    </div>
  );
}
