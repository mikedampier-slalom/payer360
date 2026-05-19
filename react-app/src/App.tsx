import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import TopNav from './components/TopNav';
import ChatWidget from './components/ChatWidget';
import ErrorBoundary from './components/ErrorBoundary';
import Home from './pages/Home';
import MedicalLossRatio from './pages/MedicalLossRatio';
import ClaimsDenials from './pages/ClaimsDenials';
import MemberRenewals from './pages/MemberRenewals';
import MemberSatisfaction from './pages/MemberSatisfaction';
import CombinedRatio from './pages/CombinedRatio';
import ClaimsSettlement from './pages/ClaimsSettlement';
import ProviderNetwork from './pages/ProviderNetwork';
import Build from './pages/Build';

const queryClient = new QueryClient();

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <div className="min-h-screen bg-black">
          <TopNav />
          <main className="pt-14 px-6 pb-6">
            <ErrorBoundary>
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/mlr" element={<MedicalLossRatio />} />
                <Route path="/denials" element={<ClaimsDenials />} />
                <Route path="/renewals" element={<MemberRenewals />} />
                <Route path="/satisfaction" element={<MemberSatisfaction />} />
                <Route path="/combined-ratio" element={<CombinedRatio />} />
                <Route path="/settlement" element={<ClaimsSettlement />} />
                <Route path="/network" element={<ProviderNetwork />} />
                <Route path="/build" element={<Build />} />
              </Routes>
            </ErrorBoundary>
          </main>
          <ChatWidget />
        </div>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
