import { useState } from 'react';

const phases = [
  {
    number: '01',
    title: 'Infrastructure & Data Foundation',
    description: 'Cortex Code scaffolded the entire Snowflake data platform — 5 databases (medallion architecture), 4 warehouses, governance roles, and 8 SQL scripts.',
    details: [
      'Created PAYER360_RAW, _INT, _CUR, _ML, _APP databases',
      'Built schemas for Claims, Membership, Financial, Network, and Member Experience',
      'Provisioned 4 warehouses: LOAD, XFM, BI, and ML',
      'Applied medallion architecture: Bronze → Silver → Gold layers',
    ],
    tech: 'Snowflake SQL DDL → Database & Schema Design → Warehouse Provisioning',
    prompt: '"Set up a full Payer 360 demo environment with medallion architecture, multiple schemas per domain, and dedicated warehouses."',
    color: '#29B5E8',
  },
  {
    number: '02',
    title: 'Dimensions & Fact Tables',
    description: 'Cortex Code designed 7 conformed dimension tables and 7 fact tables with 1.8M+ rows of realistic synthetic data generated entirely in Snowflake.',
    details: [
      'DIM_DATE, DIM_MEMBER (50K), DIM_PROVIDER (500), DIM_PLAN, DIM_LINE_OF_BUSINESS',
      'DIM_DIAGNOSIS_ICD10 (~200 codes), DIM_PROCEDURE_CPT (~150 codes), DIM_REGION',
      'FCT_CLAIM (~800K lines), FCT_PREMIUM (~600K member-months), FCT_ENROLLMENT (~100K events)',
      'FCT_SURVEY (~50K responses), FCT_GRIEVANCE (~15K), FCT_AUTHORIZATION (~200K), FCT_PROVIDER_CONTRACT (~5K)',
    ],
    tech: 'Star Schema Design → Snowflake GENERATOR() → Surrogate Keys → Referential Integrity',
    prompt: '"Generate realistic synthetic claims, enrollment, and premium data for a health insurer with 50K members."',
    color: '#10B981',
  },
  {
    number: '03',
    title: 'Use-Case Marts',
    description: 'For each payer analytics use case, Cortex Code designed the mart schema, wrote the INSERT logic joining multiple source tables, and seeded realistic data.',
    details: [
      'MART_MEDICAL_LOSS_RATIO — FCT_PREMIUM + DIM_LOB (ACA compliance tracking)',
      'MART_CLAIMS_DENIALS — FCT_CLAIM + provider/DX/CPT dims (denial reason analysis)',
      'MART_MEMBER_RENEWALS — FCT_ENROLLMENT + member/plan dims (retention & churn)',
      'MART_MEMBER_SATISFACTION — FCT_SURVEY + FCT_GRIEVANCE (NPS & CSAT)',
      'MART_COMBINED_RATIO — FCT_PREMIUM aggregated quarterly (loss + expense ratios)',
      'MART_CLAIMS_SETTLEMENT — FCT_CLAIM (cycle time & clean claim rates)',
      'MART_PROVIDER_NETWORK — FCT_PROVIDER_CONTRACT (network stability & turnover)',
    ],
    tech: 'Star Schema JOINs → Window Functions → Date Spine → Aggregation Logic',
    prompt: '"Build a Medical Loss Ratio mart that calculates MLR by line of business with ACA compliance flags."',
    color: '#F59E0B',
  },
  {
    number: '04',
    title: 'Semantic View & Cortex Agent',
    description: 'A unified semantic view was created spanning all 7 marts, enabling natural-language queries via Cortex Agent with text-to-SQL.',
    details: [
      'Semantic view with 7 logical tables covering all payer KPIs',
      'Cortex Agent configured (PAYER360_APP.CORTEX_ANALYST.PAYER360_AGENT)',
      'Guardrails: column-to-table mapping prevents cross-table errors',
      'SSE streaming for real-time thinking and response in the chatbot',
    ],
    tech: 'Semantic View DDL → Cortex Agent Config → REST API → SSE Streaming',
    prompt: '"Create a Cortex Agent that can answer natural language questions about MLR, denials, renewals, and network health."',
    color: '#7C3AED',
  },
  {
    number: '05',
    title: 'React Application (This App)',
    description: 'Cortex Code built this React frontend with 9 pages, Plotly/Vega charts, a floating chatbot, and a Flask proxy — iteratively debugging columns, types, and layouts.',
    details: [
      'Vite + React 19 + TypeScript scaffolded and configured',
      'Flask proxy server for Snowflake SQL API (PAT auth)',
      'Custom Plotly component (ref-based, React 19 compatible)',
      'Floating chatbot with SSE streaming + Vega-Lite chart rendering',
      '7 metric pages: MLR, Denials, Renewals, Satisfaction, Combined Ratio, Settlement, Network',
      'Iterative debugging of column names, data types, and chart rendering',
    ],
    tech: 'Vite → React → Flask → Snowflake REST API → Plotly → Vega-Lite',
    prompt: '"Create a React UI with top navigation, KPI cards, and a floating chatbot connected to our Cortex Agent."',
    color: '#EC4899',
  },
  {
    number: '06',
    title: 'Alerts & Operational Intelligence',
    description: 'Cortex Code added configurable Snowflake Alerts with metric presets and email notifications — enabling proactive monitoring of payer KPIs.',
    details: [
      '6 alert presets: MLR threshold, denial rate, renewal rate, combined ratio, settlement days, network turnover',
      'Email notifications via SYSTEM$SEND_EMAIL integration',
      'Custom alert creation with user-defined SQL conditions',
      'Alert lifecycle management: create, pause, resume, drop',
    ],
    tech: 'Snowflake Alerts → SYSTEM$SEND_EMAIL → Metric Presets → REST API',
    prompt: '"Add alerting so users get notified when MLR exceeds the ACA threshold or denial rates spike."',
    color: '#EF4444',
  },
];

const stats = [
  { label: 'SQL Scripts', value: '8' },
  { label: 'Data Rows Created', value: '1.8M+' },
  { label: 'Dimension Tables', value: '7' },
  { label: 'Fact Tables', value: '7' },
  { label: 'Marts Built', value: '7' },
  { label: 'React Pages', value: '9' },
];

export default function Build() {
  const [activePhase, setActivePhase] = useState(0);
  const phase = phases[activePhase];

  return (
    <div className="max-w-5xl mx-auto space-y-10">
      {/* Header */}
      <div className="text-center py-8">
        <h1 className="text-3xl font-bold text-white">Built with Cortex Code</h1>
        <p className="text-gray-400 mt-3 max-w-2xl mx-auto">
          This entire application — from Snowflake infrastructure to React frontend — was
          constructed through conversational AI using Snowflake's Cortex Code CLI.
          Step through each phase to see how it was built.
        </p>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {stats.map(({ label, value }) => (
          <div key={label} className="text-center p-4 rounded-lg border border-gray-800 bg-[#111]">
            <div className="text-2xl font-bold text-[#29B5E8]">{value}</div>
            <div className="text-xs text-gray-400 mt-1">{label}</div>
          </div>
        ))}
      </div>

      {/* Progress bar */}
      <div className="space-y-3">
        <div className="flex items-center gap-1">
          {phases.map((p, i) => (
            <button
              key={p.number}
              onClick={() => setActivePhase(i)}
              className="flex-1 h-2 rounded-full transition-all duration-300"
              style={{
                backgroundColor: i <= activePhase ? p.color : '#333',
                opacity: i === activePhase ? 1 : i < activePhase ? 0.6 : 0.3,
              }}
              title={p.title}
            />
          ))}
        </div>
        <div className="flex justify-between text-xs text-gray-500">
          <span>Phase 01</span>
          <span>Phase 0{phases.length}</span>
        </div>
      </div>

      {/* Active phase display */}
      <div
        className="rounded-xl border bg-[#0a0a0a] p-8 transition-all duration-500"
        style={{ borderColor: `${phase.color}40` }}
      >
        {/* Phase badge + title */}
        <div className="flex items-center gap-3 mb-4">
          <span
            className="text-sm font-bold px-3 py-1 rounded-full"
            style={{ backgroundColor: `${phase.color}20`, color: phase.color }}
          >
            PHASE {phase.number}
          </span>
          <h2 className="text-2xl font-bold text-white">{phase.title}</h2>
        </div>

        {/* Description */}
        <p className="text-gray-300 mb-6">{phase.description}</p>

        {/* Two-column: details + prompt */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Details */}
          <div>
            <h4 className="text-xs uppercase tracking-wide text-gray-500 mb-2">What was built</h4>
            <ul className="space-y-2">
              {phase.details.map((d, i) => (
                <li key={i} className="text-sm text-gray-300 flex items-start gap-2">
                  <span style={{ color: phase.color }} className="mt-0.5">●</span>
                  {d}
                </li>
              ))}
            </ul>
          </div>

          {/* Prompt + tech */}
          <div className="space-y-4">
            <div>
              <h4 className="text-xs uppercase tracking-wide text-gray-500 mb-2">Example prompt</h4>
              <div className="bg-[#111] border border-gray-800 rounded-lg p-3 text-sm text-gray-300 italic">
                {phase.prompt}
              </div>
            </div>
            <div>
              <h4 className="text-xs uppercase tracking-wide text-gray-500 mb-2">Tech stack</h4>
              <div className="text-sm text-gray-400">{phase.tech}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation buttons */}
      <div className="flex justify-between items-center">
        <button
          onClick={() => setActivePhase(Math.max(0, activePhase - 1))}
          disabled={activePhase === 0}
          className="px-5 py-2 rounded-lg border border-gray-700 text-gray-300 text-sm hover:border-gray-500 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
        >
          ← Previous
        </button>
        <span className="text-sm text-gray-500">
          {activePhase + 1} of {phases.length}
        </span>
        <button
          onClick={() => setActivePhase(Math.min(phases.length - 1, activePhase + 1))}
          disabled={activePhase === phases.length - 1}
          className="px-5 py-2 rounded-lg text-sm font-medium transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          style={{ backgroundColor: `${phase.color}20`, color: phase.color, borderColor: `${phase.color}40` }}
        >
          Next →
        </button>
      </div>

      {/* Architecture Flow */}
      <div className="rounded-lg border border-gray-800 bg-[#0a0a0a] p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Architecture Flow</h2>
        <div className="flex flex-wrap items-center justify-center gap-2 text-xs">
          {[
            { label: 'Source Systems', sub: 'EDI, Enrollment, Premium, Surveys', color: '#29B5E8' },
            { label: '→', sub: '', color: '' },
            { label: 'Snowflake RAW', sub: 'Bronze Layer', color: '#6B7280' },
            { label: '→', sub: '', color: '' },
            { label: 'Snowflake CUR', sub: 'Gold Marts', color: '#10B981' },
            { label: '→', sub: '', color: '' },
            { label: 'Cortex Agent', sub: 'NL Queries', color: '#7C3AED' },
            { label: '→', sub: '', color: '' },
            { label: 'React + Flask', sub: 'This App', color: '#EF4444' },
          ].map((item, i) =>
            item.sub === '' ? (
              <span key={i} className="text-gray-600 text-lg">→</span>
            ) : (
              <div
                key={i}
                className="px-3 py-2 rounded border text-center min-w-[100px]"
                style={{ borderColor: `${item.color}50`, backgroundColor: `${item.color}10` }}
              >
                <div style={{ color: item.color }} className="font-medium">{item.label}</div>
                <div className="text-gray-500 mt-0.5">{item.sub}</div>
              </div>
            )
          )}
        </div>
      </div>

      {/* How it worked */}
      <div className="rounded-lg border border-gray-800 bg-[#0a0a0a] p-6">
        <h2 className="text-lg font-semibold text-white mb-4">How Cortex Code Built This</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="p-4 rounded-lg bg-[#111] border border-gray-800">
            <div className="text-2xl mb-2">💬</div>
            <h4 className="text-sm font-medium text-white mb-1">Conversational</h4>
            <p className="text-xs text-gray-400">
              Every feature was requested in natural language. "Build a Medical Loss Ratio mart with ACA compliance flags by line of business."
            </p>
          </div>
          <div className="p-4 rounded-lg bg-[#111] border border-gray-800">
            <div className="text-2xl mb-2">🔄</div>
            <h4 className="text-sm font-medium text-white mb-1">Iterative</h4>
            <p className="text-xs text-gray-400">
              Charts not rendering? Wrong column names? Cortex Code debugged in real-time — testing queries, fixing types, adjusting margins.
            </p>
          </div>
          <div className="p-4 rounded-lg bg-[#111] border border-gray-800">
            <div className="text-2xl mb-2">⚡</div>
            <h4 className="text-sm font-medium text-white mb-1">Full-Stack</h4>
            <p className="text-xs text-gray-400">
              From CREATE DATABASE to npm run dev — infrastructure, data engineering, semantic views, Cortex Agent, and React all in one conversation.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
