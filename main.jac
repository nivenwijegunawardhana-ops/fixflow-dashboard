import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from .components.MaintenanceDashboard { MaintenanceDashboard }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<MaintenanceDashboard />} />
        </Routes>
    </Router>;
}
