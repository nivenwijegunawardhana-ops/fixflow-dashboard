import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.field { Field, FieldLabel, FieldGroup }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.button { Button }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { DashboardSquare01Icon, File01Icon, Alert01Icon, Calendar01Icon }
sv import from ..services.maintenanceService { initialize_samples, list_tickets, list_slots, get_ticket_summary, create_ticket, transition_ticket_status }

def:pub MaintenanceDashboard() -> JsxElement {
    has location: str = "";
    has description: str = "";
    has tickets: list[dict[str, any]] = [];
    has slots: list[dict[str, any]] = [];
    has summary: dict[str, any] = {};
    has loading: bool = True;
    has load_error: str = "";
    has success_message: str = "";
    has action_error: str = "";
    has submitting: bool = False;
    has updating_ticket: int = 0;
    def handle_location(e: ChangeEvent) { location = e.target.value; }
    def handle_description(e: ChangeEvent) { description = e.target.value; }

    async def refresh_data() {
        tickets = await list_tickets();
        slots = await list_slots();
        summary = await get_ticket_summary();
    }

    async def handle_submit() {
        success_message = "";
        action_error = "";
        if len(location.strip()) < 2 or len(description.strip()) < 5 {
            action_error = "Enter a meaningful location and issue description.";
            return;
        }
        submitting = True;
        try {
            result = await create_ticket(location, description);
            if result["ok"] as bool {
                ticket_id = result["ticket_id"] as int;
                await refresh_data();
                success_message = "Report saved as Ticket #" + str(ticket_id) + ".";
                location = "";
                description = "";
            } else {
                action_error = result["message"] as str;
            }
        } except Exception {
            action_error = "Could not save the report. Please try again.";
        }
        submitting = False;
    }

    async def update_status(ticket_id: int) {
        action_error = "";
        updating_ticket = ticket_id;
        try {
            result = await transition_ticket_status(ticket_id);
            if result["updated"] as bool {
                await refresh_data();
                success_message = "Ticket #" + str(ticket_id) + " status updated to " + (result["status"] as str) + ".";
            } else {
                action_error = "Ticket status could not be updated.";
            }
        } except Exception {
            action_error = "Could not update ticket status. Please try again.";
        }
        updating_ticket = 0;
    }

    async can with entry {
        try {
            await initialize_samples();
            await refresh_data();
        } except Exception {
            load_error = "Maintenance data could not be loaded. Refresh to try again.";
        }
        loading = False;
    }

    return <main className="min-h-screen bg-muted/40 px-4 py-8 sm:px-6 lg:py-12">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <header className="flex flex-wrap items-center gap-4 rounded-2xl border bg-card px-5 py-5 shadow-sm sm:px-7">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-6" /></div>
                <div className="flex flex-col gap-1"><h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">{"FixFlow AI"}</h1><p className="text-sm text-muted-foreground">{"Campus Maintenance Assistant"}</p></div>
                <div className="ml-auto hidden items-center gap-2 rounded-full border bg-background px-3 py-1.5 text-xs font-medium text-muted-foreground sm:flex"><span className="size-2 rounded-full bg-primary" />{"Campus operations"}</div>
            </header>

            <section className="flex flex-col gap-4" aria-label="Maintenance summary">
                <div className="flex flex-col gap-1"><h2 className="text-xl font-semibold tracking-tight">{"Maintenance overview"}</h2><p className="text-sm text-muted-foreground">{"A clear view of campus reports and repair activity."}</p></div>
                {if load_error != "" { <p className="text-sm text-destructive" role="alert">{load_error}</p> }}
                {if success_message != "" { <p className="text-sm text-primary" role="status">{success_message}</p> }}
                {if action_error != "" { <p className="text-sm text-destructive" role="alert">{action_error}</p> }}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    <Card className="shadow-sm transition-shadow hover:shadow-md"><CardContent className="flex flex-col gap-5 pt-5"><div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Total Tickets"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-4" /></div></div><span className="text-3xl font-semibold tracking-tight tabular-nums">{str(summary["total_tickets"] if summary else 0) if not loading else "…"}</span></CardContent></Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md"><CardContent className="flex flex-col gap-5 pt-5"><div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Merged Duplicates"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-4" /></div></div><span className="text-3xl font-semibold tracking-tight tabular-nums">{str(summary["merged_duplicates"] if summary else 0) if not loading else "…"}</span></CardContent></Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md"><CardContent className="flex flex-col gap-5 pt-5"><div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Urgent Hazards"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Alert01Icon} strokeWidth={2} className="size-4" /></div></div><span className="text-3xl font-semibold tracking-tight tabular-nums">{str(summary["urgent_hazards"] if summary else 0) if not loading else "…"}</span></CardContent></Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md"><CardContent className="flex flex-col gap-5 pt-5"><div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Scheduled Repairs"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-4" /></div></div><span className="text-3xl font-semibold tracking-tight tabular-nums">{str(summary["scheduled_repairs"] if summary else 0) if not loading else "…"}</span></CardContent></Card>
                </div>
            </section>

            <div className="grid grid-cols-1 items-start gap-5 lg:grid-cols-5">
                <Card className="shadow-sm lg:col-span-2"><CardHeader><CardTitle>{"Report a Problem"}</CardTitle><CardDescription>{"Let the campus team know what needs attention."}</CardDescription></CardHeader><CardContent><form onSubmit={lambda (e: FormEvent) { e.preventDefault(); handle_submit(); }} className="flex flex-col gap-5"><FieldGroup><Field><FieldLabel htmlFor="location">{"Location"}</FieldLabel><Input id="location" value={location} onChange={handle_location} placeholder="e.g. Science Building, room 204" className="h-10" /></Field><Field><FieldLabel htmlFor="description">{"Issue Description"}</FieldLabel><Textarea id="description" value={description} onChange={handle_description} placeholder="Describe the maintenance issue" className="min-h-28 resize-y" /></Field></FieldGroup><Button type="button" disabled={submitting} onClick={lambda { handle_submit(); }} className="h-10 w-full shadow-sm">{"Submit Report" if not submitting else "Submitting report…"}</Button></form></CardContent></Card>

                <Card className="shadow-sm lg:col-span-3"><CardHeader><CardTitle>{"Recent Maintenance Tickets"}</CardTitle><CardDescription>{"The latest reports from around campus."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">
                    {if loading { <p className="py-8 text-center text-sm text-muted-foreground">{"Loading maintenance tickets…"}</p> }}
                    {if not loading and len(tickets) == 0 and load_error == "" { <Empty className="rounded-xl border border-dashed bg-muted/20 py-10"><EmptyHeader><EmptyMedia variant="icon"><HugeiconsIcon icon={File01Icon} strokeWidth={2} /></EmptyMedia><EmptyTitle>{"No reports yet"}</EmptyTitle><EmptyDescription>{"Submitted maintenance reports will appear here."}</EmptyDescription></EmptyHeader></Empty> }}
                    {for ticket in tickets {
                        <article key={str(ticket["ticket_id"])} className="rounded-xl border bg-background p-4 shadow-sm">
                            <div className="flex flex-wrap items-start justify-between gap-3"><div className="flex flex-col gap-1"><p className="text-sm font-semibold">{"Ticket #" + str(ticket["ticket_id"]) + " · " + str(ticket["location"])}</p><p className="text-sm text-muted-foreground">{str(ticket["issue"])}</p></div><span className="rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary">{str(ticket["status"])}</span></div>
                            <div className="mt-3 flex flex-wrap items-center justify-between gap-3"><div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground"><span>{str(ticket["category"])}</span><span>{str(ticket["priority"]) + " priority"}</span><span>{str(ticket["report_count"]) + " report"}</span><span>{str(ticket["scheduled_time"])}</span></div>{if str(ticket["status"]) == "Open" { <Button type="button" size="sm" variant="outline" disabled={updating_ticket == (ticket["ticket_id"] as int)} onClick={lambda { update_status(ticket["ticket_id"] as int); }}>{"Mark In Progress"}</Button> } elif str(ticket["status"]) == "In Progress" { <Button type="button" size="sm" variant="outline" disabled={updating_ticket == (ticket["ticket_id"] as int)} onClick={lambda { update_status(ticket["ticket_id"] as int); }}>{"Mark Resolved"}</Button> }}</div>
                        </article>
                    }}
                </CardContent></Card>
            </div>

            <Card className="shadow-sm"><CardHeader><CardTitle>{"Technician Repair Schedule"}</CardTitle><CardDescription>{"Sample technician time slots and current availability."}</CardDescription></CardHeader><CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">{if loading { <p className="text-sm text-muted-foreground">{"Loading repair schedule…"}</p> }}{for slot in slots { <div key={str(slot["slot_id"])} className="flex flex-col gap-2 rounded-xl border bg-background p-4 shadow-sm"><div className="flex items-center justify-between gap-2"><span className="text-sm font-semibold">{str(slot["label"])}</span><span className={"rounded-full px-2 py-1 text-xs font-medium " + ("bg-primary/10 text-primary" if slot["is_available"] else "bg-muted text-muted-foreground")}>{"Available" if slot["is_available"] else "Occupied"}</span></div><p className="text-xs text-muted-foreground">{str(slot["slot_type"]) + " slot"}</p>{if str(slot["occupied_by"]) != "" { <p className="text-xs text-muted-foreground">{str(slot["occupied_by"])}</p> }}</div> }}</CardContent></Card>
            <footer className="flex justify-center border-t pt-5 text-xs text-muted-foreground">{"Campus Maintenance Assistant"}</footer>
        </div>
    </main>;
}
