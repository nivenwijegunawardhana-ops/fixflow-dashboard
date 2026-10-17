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

def:pub initialize_samples() -> dict[str, int] {
    shared = root.shared;
    slots = [shared -->][?:TimeSlot];
    if len([s for s in slots if s.slot_id == 1]) == 0 { slot = shared ++> TimeSlot(slot_id=1, label="Today 1:00 PM", slot_type="Emergency", is_available=True); grant(slot, level=ReadPerm); }
    if len([s for s in slots if s.slot_id == 2]) == 0 { slot = shared ++> TimeSlot(slot_id=2, label="Today 4:00 PM", slot_type="Standard", is_available=True); grant(slot, level=ReadPerm); }
    if len([s for s in slots if s.slot_id == 3]) == 0 { slot = shared ++> TimeSlot(slot_id=3, label="Tomorrow 10:00 AM", slot_type="Standard", is_available=False); grant(slot, level=ReadPerm); }
    if len([s for s in slots if s.slot_id == 4]) == 0 { slot = shared ++> TimeSlot(slot_id=4, label="Tomorrow 2:00 PM", slot_type="Standard", is_available=False); grant(slot, level=ReadPerm); }
    tickets = [shared -->][?:Ticket];
    ticket_101: Ticket | None = None;
    ticket_102: Ticket | None = None;
    for ticket in tickets {
        if ticket.ticket_id == 101 { ticket_101 = ticket; }
        if ticket.ticket_id == 102 { ticket_102 = ticket; }
    }
    if ticket_101 is None {
        ticket_101 = shared ++> Ticket(ticket_id=101, location="Room 5", issue="Ceiling fan is not spinning", category="Electrical", priority="Medium", report_count=1, status="Open", agent_notes="Initial report logged and scheduled.");
        grant(ticket_101, level=ReadPerm);
    }
    if ticket_102 is None {
        ticket_102 = shared ++> Ticket(ticket_id=102, location="Lab 2", issue="Projector HDMI cable loose", category="Equipment", priority="Low", report_count=1, status="Open", agent_notes="Routine equipment check scheduled.");
        grant(ticket_102, level=ReadPerm);
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
    return {"tickets": len([shared -->][?:Ticket]), "slots": len([shared -->][?:TimeSlot])};
}

def:pub list_tickets() -> list[dict[str, any]] {
    tickets: list[dict[str, any]] = [];
    for ticket in [root.shared -->][?:Ticket] {
        assigned = [ticket ->:ScheduledFor:->][?:TimeSlot];
        scheduled_time = "Unscheduled";
        if len(assigned) > 0 { scheduled_time = assigned[0].label; }
        tickets.append({
            "ticket_id": ticket.ticket_id,
            "location": ticket.location,
            "issue": ticket.issue,
            "category": ticket.category,
            "priority": ticket.priority,
            "report_count": ticket.report_count,
            "status": ticket.status,
            "scheduled_time": scheduled_time
        });
    }
    return tickets;
}

def:pub list_slots() -> list[dict[str, any]] {
    slots: list[dict[str, any]] = [];
    for slot in [root.shared -->][?:TimeSlot] {
        assigned = [slot <-:ScheduledFor:<-][?:Ticket];
        occupied_by = "";
        if len(assigned) > 0 { occupied_by = "Ticket #" + str(assigned[0].ticket_id); }
        slots.append({
            "slot_id": slot.slot_id,
            "label": slot.label,
            "slot_type": slot.slot_type,
            "is_available": slot.is_available and len(assigned) == 0,
            "occupied_by": occupied_by
        });
    }
    return slots;
}

def:pub get_ticket_summary() -> dict[str, int] {
    tickets = [root.shared -->][?:Ticket];
    scheduled_repairs = 0;
    for ticket in tickets {
        if len([ticket ->:ScheduledFor:->][?:TimeSlot]) > 0 { scheduled_repairs += 1; }
    }
    return {
        "total_tickets": len(tickets),
        "merged_duplicates": 0,
        "urgent_hazards": 0,
        "scheduled_repairs": scheduled_repairs
    };
}
