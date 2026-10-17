import from services.maintenanceService { Ticket, TimeSlot, TicketTombstone, ScheduledFor, initialize_samples, list_tickets, list_slots, get_ticket_summary, create_ticket, transition_ticket_status, delete_ticket }
import from services.maintenanceService { Ticket, TimeSlot, TicketTombstone, ScheduledFor, initialize_samples, list_tickets, list_slots, get_ticket_summary, create_ticket, transition_ticket_status, delete_ticket }
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
