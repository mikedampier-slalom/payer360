import { NavLink } from 'react-router-dom';

const links = [
  { to: '/mlr', label: 'MLR' },
  { to: '/denials', label: 'Denials' },
  { to: '/renewals', label: 'Renewals' },
  { to: '/satisfaction', label: 'Satisfaction' },
  { to: '/combined-ratio', label: 'Combined Ratio' },
  { to: '/settlement', label: 'Settlement' },
  { to: '/network', label: 'Network' },
];

export default function TopNav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 h-14 bg-[#111111] border-b border-gray-800 flex items-center px-6">
      <NavLink to="/" className="text-[#29B5E8] font-bold text-lg mr-8 whitespace-nowrap">
        Payer 360
      </NavLink>
      <div className="flex gap-1 overflow-x-auto">
        {links.map(({ to, label }) => (
          <NavLink
            key={to}
            to={to}
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
