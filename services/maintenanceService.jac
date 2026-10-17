node Ticket {
    has ticket_id: int;
    has location: str;
    has issue: str;
    has category: str;
    has priority: str;
    has report_count: int;
    has status: str;
    has agent_notes: str;
}

node TimeSlot {
    has slot_id: int;
    has label: str;
    has slot_type: str;
    has is_available: bool;
}

edge ScheduledFor: Ticket --> TimeSlot {}

walker SeedMaintenanceSamples {
    can initialize with Root entry {
        shared = here.shared;
        slots = [shared -->][?:TimeSlot];
        for (slot_id, label, slot_type, available) in [
            (1, "Today 1:00 PM", "Emergency", True),
            (2, "Today 4:00 PM", "Standard", True),
            (3, "Tomorrow 10:00 AM", "Standard", False),
            (4, "Tomorrow 2:00 PM", "Standard", False)
        ] {
            found = False;
            for slot in slots {
                if slot.slot_id == slot_id { found = True; }
            }
            if not found {
                shared ++> TimeSlot(slot_id=slot_id, label=label, slot_type=slot_type, is_available=available);
            }
        }
        tickets = [shared -->][?:Ticket];
        ticket_101 = None;
        ticket_102 = None;
        for ticket in tickets {
            if ticket.ticket_id == 101 { ticket_101 = ticket; }
            if ticket.ticket_id == 102 { ticket_102 = ticket; }
        }
        if ticket_101 is None {
            ticket_101 = shared ++> Ticket(
                ticket_id=101,
                location="Room 5",
                issue="Ceiling fan is not spinning",
                category="Electrical",
                priority="Medium",
                report_count=1,
                status="Open",
                agent_notes="Initial report logged and scheduled."
            );
        }
        if ticket_102 is None {
            ticket_102 = shared ++> Ticket(
                ticket_id=102,
                location="Lab 2",
                issue="Projector HDMI cable loose",
                category="Equipment",
                priority="Low",
                report_count=1,
                status="Open",
                agent_notes="Routine equipment check scheduled."
            );
        }
        slots = [shared -->][?:TimeSlot];
        for slot in slots {
            if slot.slot_id == 3 and ticket_101 is not None {
                connected = [ticket_101 ->:ScheduledFor:->][?:TimeSlot];
                if len(connected) == 0 { ticket_101 +>:ScheduledFor:+> slot; }
                slot.is_available = False;
            }
            if slot.slot_id == 4 and ticket_102 is not None {
                connected = [ticket_102 ->:ScheduledFor:->][?:TimeSlot];
                if len(connected) == 0 { ticket_102 +>:ScheduledFor:+> slot; }
                slot.is_available = False;
            }
        }
    }
}

walker ListMaintenanceTickets {
    has tickets: list[dict] = [];
    has reports: list[list[dict]] = [];

    can start with Root entry {
        visit [here.shared -->];
    }

    can collect_ticket with Ticket entry {
        slots = [here ->:ScheduledFor:->][?:TimeSlot];
        scheduled_time = "Unscheduled";
        if len(slots) > 0 { scheduled_time = slots[0].label; }
        self.tickets.append({
            "ticket_id": here.ticket_id,
            "location": here.location,
            "issue": here.issue,
            "category": here.category,
            "priority": here.priority,
            "report_count": here.report_count,
            "status": here.status,
            "scheduled_time": scheduled_time
        });
    }

    can finish with Root exit {
        report self.tickets;
    }
}

walker ListMaintenanceSlots {
    has slots: list[dict] = [];
    has reports: list[list[dict]] = [];

    can start with Root entry {
        visit [here.shared -->];
    }

    can collect_slot with TimeSlot entry {
        assignments = [here <-:ScheduledFor:<-][?:Ticket];
        occupied_by = "";
        if len(assignments) > 0 { occupied_by = "Ticket #" + str(assignments[0].ticket_id); }
        available = here.is_available and len(assignments) == 0;
        self.slots.append({
            "slot_id": here.slot_id,
            "label": here.label,
            "slot_type": here.slot_type,
            "is_available": available,
            "occupied_by": occupied_by
        });
    }

    can finish with Root exit {
        report self.slots;
    }
}

walker GetMaintenanceSummary {
    has total_tickets: int = 0;
    has scheduled_repairs: int = 0;
    has reports: list[dict] = [];

    can start with Root entry {
        visit [here.shared -->];
    }

    can count_ticket with Ticket entry {
        self.total_tickets += 1;
        if len([here ->:ScheduledFor:->][?:TimeSlot]) > 0 { self.scheduled_repairs += 1; }
    }

    can finish with Root exit {
        report {
            "total_tickets": self.total_tickets,
            "merged_duplicates": 0,
            "urgent_hazards": 0,
            "scheduled_repairs": self.scheduled_repairs
        };
    }
}

def:pub initialize_samples() {
    shared = root.shared;
    slots = [shared -->][?:TimeSlot];
    if len([s for s in slots if s.slot_id == 1]) == 0 { shared ++> TimeSlot(slot_id=1, label="Today 1:00 PM", slot_type="Emergency", is_available=True); }
    if len([s for s in slots if s.slot_id == 2]) == 0 { shared ++> TimeSlot(slot_id=2, label="Today 4:00 PM", slot_type="Standard", is_available=True); }
    if len([s for s in slots if s.slot_id == 3]) == 0 { shared ++> TimeSlot(slot_id=3, label="Tomorrow 10:00 AM", slot_type="Standard", is_available=False); }
    if len([s for s in slots if s.slot_id == 4]) == 0 { shared ++> TimeSlot(slot_id=4, label="Tomorrow 2:00 PM", slot_type="Standard", is_available=False); }
    tickets = [shared -->][?:Ticket];
    ticket_101: Ticket | None = None;
    ticket_102: Ticket | None = None;
    for ticket in tickets {
        if ticket.ticket_id == 101 { ticket_101 = ticket; }
        if ticket.ticket_id == 102 { ticket_102 = ticket; }
    }
    if ticket_101 is None {
        ticket_101 = shared ++> Ticket(ticket_id=101, location="Room 5", issue="Ceiling fan is not spinning", category="Electrical", priority="Medium", report_count=1, status="Open", agent_notes="Initial report logged and scheduled.");
    }
    if ticket_102 is None {
        ticket_102 = shared ++> Ticket(ticket_id=102, location="Lab 2", issue="Projector HDMI cable loose", category="Equipment", priority="Low", report_count=1, status="Open", agent_notes="Routine equipment check scheduled.");
    }
    slots = [shared -->][?:TimeSlot];
    for slot in slots {
        if slot.slot_id == 3 and ticket_101 is not None {
            assigned = [ticket_101 ->:ScheduledFor:->][?:TimeSlot];
            if len(assigned) == 0 { ticket_101 +>:ScheduledFor:+> slot; }
        }
        if slot.slot_id == 4 and ticket_102 is not None {
            assigned = [ticket_102 ->:ScheduledFor:->][?:TimeSlot];
            if len(assigned) == 0 { ticket_102 +>:ScheduledFor:+> slot; }
        }
    }
}

def:pub list_tickets() -> list[dict] {
    result = root spawn ListMaintenanceTickets();
    if len(result.reports) > 0 { return result.reports[0] as list[dict]; }
    return [];
}

def:pub list_slots() -> list[dict] {
    result = root spawn ListMaintenanceSlots();
    if len(result.reports) > 0 { return result.reports[0] as list[dict]; }
    return [];
}

def:pub get_ticket_summary() -> dict {
    result = root spawn GetMaintenanceSummary();
    if len(result.reports) > 0 { return result.reports[0] as dict; }
    return {"total_tickets": 0, "merged_duplicates": 0, "urgent_hazards": 0, "scheduled_repairs": 0};
}
