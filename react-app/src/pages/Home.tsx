import { Link } from 'react-router-dom';
import DataTable from '../components/DataTable';

const dataSources = [
  { source: 'Claims EDI', data: '837I/837P submissions, 835 remittance advice, CARC/RARC codes' },
  { source: 'Enrollment Systems', data: 'Member enrollment, plan selections, renewals, terminations' },
  { source: 'Premium Billing', data: 'Premium earned, incurred claims allocation, MLR components' },
  { source: 'Provider Credentialing', data: 'Network contracts, credentialing status, quality scores' },
  { source: 'Member Surveys', data: 'NPS surveys, CAHPS data, satisfaction scores' },
  { source: 'Grievance System', data: 'Member complaints, appeals, resolution tracking' },
  { source: 'Snowflake Marketplace', data: 'CMS reference data, ICD-10/CPT codes, demographic data' },
];

const pages = [
  { to: '/mlr', label: 'Medical Loss Ratio', desc: 'Are we meeting ACA MLR thresholds by line of business?', sources: 'Premium Billing, Claims EDI' },
  { to: '/denials', label: 'Claims Denials', desc: 'What are the top denial categories and appeal success rates?', sources: 'Claims EDI (837/835)' },
  { to: '/renewals', label: 'Member Renewals', desc: 'Which members are at risk of lapsing and what drives retention?', sources: 'Enrollment Systems' },
  { to: '/satisfaction', label: 'Member Satisfaction', desc: 'What is our NPS and how does it correlate with grievances?', sources: 'Member Surveys, Grievance System' },
  { to: '/combined-ratio', label: 'Combined Ratio', desc: 'What is our loss and expense ratio by line of business?', sources: 'Premium Billing, Claims EDI' },
  { to: '/settlement', label: 'Claims Settlement', desc: 'How fast are we processing and paying claims?', sources: 'Claims EDI (837/835)' },
  { to: '/network', label: 'Provider Network', desc: 'What is our network turnover rate and provider quality?', sources: 'Provider Credentialing' },
];

export default function Home() {
  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white">Payer 360 — Demo Overview</h1>
        <p className="text-gray-400 mt-2">
          A health insurance analytics dashboard powered by Snowflake, Cortex AI, and React.
        </p>
      </div>

      <section>
        <h2 className="text-xl font-semibold text-white mb-3">Data Sources</h2>
        <DataTable
          columns={[
            { key: 'source', label: 'Source System' },
            { key: 'data', label: 'Data Provided' },
          ]}
          data={dataSources}
        />
      </section>

      <section>
        <h2 className="text-xl font-semibold text-white mb-3">Platform Architecture</h2>
        <ul className="list-disc list-inside text-gray-300 space-y-1 text-sm">
          <li><strong>Ingestion:</strong> Snowflake Dynamic Tables (bronze → silver → gold) with incremental refresh</li>
          <li><strong>Curated Layer:</strong> <code>PAYER360_CUR</code> — star-schema marts for each use case</li>
          <li><strong>ML Layer:</strong> <code>PAYER360_ML</code> — Cortex ML forecasting, anomaly detection, classification</li>
          <li><strong>App Layer:</strong> <code>PAYER360_APP</code> — React frontend, Payer Chat (Cortex Agent)</li>
          <li><strong>Compute:</strong> Dedicated warehouses for load, transform, BI, and ML workloads</li>
        </ul>
      </section>

      <section>
        <h2 className="text-xl font-semibold text-white mb-3">Pages</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {pages.map(({ to, label, desc, sources }) => (
            <Link
              key={to}
              to={to}
              className="block p-4 rounded-lg border border-gray-800 bg-[#111] hover:border-[#29B5E8] transition-colors"
            >
              <div className="text-white font-medium text-sm">{label}</div>
              <div className="text-gray-400 text-xs mt-1">{desc}</div>
              <div className="text-[#29B5E8] text-xs mt-2 opacity-75">{sources}</div>
            </Link>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-xl font-semibold text-white mb-3">Glossary of Abbreviations</h2>
        <DataTable
          columns={[
            { key: 'abbr', label: 'Abbreviation' },
            { key: 'term', label: 'Full Term' },
          ]}
          data={[
            { abbr: 'MLR', term: 'Medical Loss Ratio — percentage of premium spent on claims and quality improvement' },
            { abbr: 'LOB', term: 'Line of Business — market segment (Individual, Small Group, Large Group, Medicare Advantage, Medicaid)' },
            { abbr: 'NPS', term: 'Net Promoter Score — member loyalty metric (-100 to +100)' },
            { abbr: 'CAHPS', term: 'Consumer Assessment of Healthcare Providers and Systems — standardized survey' },
            { abbr: 'CARC', term: 'Claim Adjustment Reason Code — explains payer payment adjustments' },
            { abbr: 'RARC', term: 'Remittance Advice Remark Code — supplemental denial/adjustment detail' },
            { abbr: 'EPO', term: 'Exclusive Provider Organization — in-network only, no referral required' },
            { abbr: 'HMO', term: 'Health Maintenance Organization — in-network only, PCP gatekeeper' },
            { abbr: 'PPO', term: 'Preferred Provider Organization — in/out network, no referral' },
            { abbr: 'HDHP', term: 'High Deductible Health Plan — lower premium, higher deductible, HSA-eligible' },
            { abbr: 'POS', term: 'Point of Service — hybrid HMO/PPO plan' },
            { abbr: 'OOP', term: 'Out of Pocket — member cost-sharing maximum' },
            { abbr: 'QI', term: 'Quality Improvement — activities that improve health outcomes (counts toward MLR)' },
            { abbr: 'EDI', term: 'Electronic Data Interchange — standardized healthcare transaction format (X12)' },
          ]}
        />
      </section>
    </div>
  );
}
