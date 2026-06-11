import { Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./pages/dashboard";
import Portfolio from "./pages/portfolio";
import Transactions from "./pages/transactions";
import Equity from "./pages/equity";
import MutualFunds from "./pages/mutual-funds";
import Deposits from "./pages/deposits";
import Bonds from "./pages/bonds";
import BondDetailPage from "./pages/bonds/BondDetailPage";
import Fno from "./pages/fno";
import Algo from "./pages/algo";
import IntegrationRoutes from "./pages/integrations/routes";
import Login from "./pages/auth/Login";
import Register from "./pages/auth/Register";
import Toast from "./components/common/Toast";

export default function App() {
  return (
    <>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/portfolio" element={<Portfolio />} />
        <Route path="/transactions" element={<Transactions />} />
        <Route path="/equity" element={<Equity />} />
        <Route path="/mutual-funds" element={<MutualFunds />} />
        <Route path="/deposits" element={<Deposits />} />
        <Route path="/bonds" element={<Bonds />} />
        <Route path="/bonds/:bondId" element={<BondDetailPage />} />
        <Route path="/fno" element={<Fno />} />
        <Route path="/algo" element={<Algo />} />
        <Route path="/integrations/*" element={<IntegrationRoutes />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
      <Toast />
    </>
  );
}
