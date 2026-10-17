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

node TicketTombstone {
    has ticket_id: int;
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
    deleted_101 = len([shared -->][?:TicketTombstone, ticket_id == 101]) > 0;
    deleted_102 = len([shared -->][?:TicketTombstone, ticket_id == 102]) > 0;
    if ticket_101 is None and not deleted_101 {
        ticket_101 = shared ++> Ticket(ticket_id=101, location="Room 5", issue="Ceiling fan is not spinning", category="Electrical", priority="Medium", report_count=1, status="Open", agent_notes="Initial report logged and scheduled.");
        grant(ticket_101, level=ReadPerm);
    }
    if ticket_102 is None and not deleted_102 {
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

walker TransitionTicketStatus {
    has ticket_id: int;
    has reports: list[dict[str, any]] = [];

    can update with Ticket entry {
        if here.ticket_id == self.ticket_id {
            if here.status == "Open" {
                here.status = "In Progress";
                self.reports.append({"ticket_id": here.ticket_id, "status": here.status, "updated": True});
            } elif here.status == "In Progress" {
                here.status = "Resolved";
                self.reports.append({"ticket_id": here.ticket_id, "status": here.status, "updated": True});
            } else {
                self.reports.append({"ticket_id": here.ticket_id, "status": here.status, "updated": False});
            }
            disengage;
        }
    }
}

def:pub create_ticket(location: str, issue: str) -> dict[str, any] {
    clean_location = location.strip();
    clean_issue = issue.strip();
    if len(clean_location) < 2 or len(clean_issue) < 5 {
        return {"ok": False, "message": "Enter a meaningful location and issue description."};
    }
    tickets = [root.shared -->][?:Ticket];
    next_id = 100;
    for ticket in tickets {
        if ticket.ticket_id > next_id { next_id = ticket.ticket_id; }
    }
    ticket = root.shared ++> Ticket(
        ticket_id=next_id + 1,
        location=clean_location,
        issue=clean_issue,
        category="Other",
        priority="Pending Review",
        report_count=1,
        status="Open",
        agent_notes="Awaiting AI assessment"
    );
    grant(ticket, level=ReadPerm);
    return {"ok": True, "ticket_id": ticket.ticket_id, "message": "Report submitted successfully."};
}

def:pub transition_ticket_status(ticket_id: int) -> dict[str, any] {
    for ticket in [root.shared -->][?:Ticket] {
        if ticket.ticket_id == ticket_id {
            if ticket.status == "Open" {
                ticket.status = "In Progress";
                return {"ticket_id": ticket_id, "status": ticket.status, "updated": True};
            } elif ticket.status == "In Progress" {
                ticket.status = "Resolved";
                return {"ticket_id": ticket_id, "status": ticket.status, "updated": True};
            }
            return {"ticket_id": ticket_id, "status": ticket.status, "updated": False};
        }
    }
    return {"ticket_id": ticket_id, "updated": False, "message": "Ticket not found."};
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

def:pub delete_ticket(ticket_id: int, confirm_id: int) -> dict[str, any] {
    if ticket_id < 1 or confirm_id != ticket_id {
        return {"ok": False, "ticket_id": ticket_id, "message": "Deletion confirmation did not match the selected ticket."};
    }
    target_id = ticket_id;
    for ticket in [root.shared -->][?:Ticket] {
        if ticket.ticket_id == ticket_id {
            linked_slots = [ticket ->:ScheduledFor:->][?:TimeSlot];
            for link in [edge ticket ->:ScheduledFor:->] { del link; }
            for slot in linked_slots {
                remaining = [slot <-:ScheduledFor:<-][?:Ticket];
                if len(remaining) == 0 { slot.is_available = True; }
            }
            if len([root.shared -->][?:TicketTombstone, ticket_id == target_id]) == 0 {
                root.shared ++> TicketTombstone(ticket_id=target_id);
            }
            del ticket;
            return {"ok": True, "ticket_id": ticket_id};
        }
    }
    tombstones = [root.shared -->][?:TicketTombstone, ticket_id == target_id];
    if len(tombstones) > 0 { return {"ok": True, "ticket_id": target_id, "already_deleted": True}; }
    return {"ok": False, "ticket_id": target_id, "message": "Ticket not found."};
}
