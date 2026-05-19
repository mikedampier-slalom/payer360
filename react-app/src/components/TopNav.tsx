import { NavLink } from 'react-router-dom';

const links = [
  { to: '/mlr', label: 'MLR', desc: 'Medical Loss Ratio — ratio of claims paid to premiums earned, with ACA compliance tracking by line of business' },
  { to: '/denials', label: 'Denials', desc: 'Claims Denial Rate — denial trends, top denial categories, appeal outcomes, and denial rates by line of business' },
  { to: '/renewals', label: 'Renewals', desc: 'Member Renewal Rate — policy retention and churn analysis by plan type, tenure distribution, and lapse reasons' },
  { to: '/satisfaction', label: 'Satisfaction', desc: 'Net Promoter Score & Member Satisfaction — NPS trends, satisfaction by topic, and grievance resolution metrics' },
  { to: '/combined-ratio', label: 'Combined Ratio', desc: 'Combined Ratio — loss ratio plus expense ratio with quarterly trends and underwriting profit/loss by LOB' },
  { to: '/settlement', label: 'Settlement', desc: 'Claims Settlement Cycle — average days to adjudicate and pay, clean claim rates, and auto-adjudication trends' },
  { to: '/network', label: 'Network', desc: 'Provider Network Stability — network size, turnover rate by specialty, termination reasons, and quality scores' },
  { to: '/build', label: 'Build', desc: 'Build — how the Payer 360 platform was constructed using Cortex Code' },
];

export default function TopNav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 h-14 bg-[#111111] border-b border-gray-800 flex items-center px-6">
      <NavLink to="/" className="text-[#29B5E8] font-bold text-lg mr-8 whitespace-nowrap">
        Payer 360
      </NavLink>
      <div className="flex gap-1 overflow-x-auto">
        {links.map(({ to, label, desc }) => (
          <NavLink
            key={to}
            to={to}
            title={desc}
            className={({ isActive }) =>
              `px-3 py-1.5 text-sm rounded transition-colors whitespace-nowrap ${
                isActive
                  ? 'text-[#29B5E8] border-b-2 border-[#29B5E8]'
                  : 'text-gray-400 hover:text-gray-200'
              }`
            }
          >
            {label}
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
