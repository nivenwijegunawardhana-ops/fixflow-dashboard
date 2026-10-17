import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.field { Field, FieldLabel, FieldGroup }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.button { Button }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { DashboardSquare01Icon, File01Icon, Alert01Icon, Calendar01Icon, Search01Icon, SparklesIcon, Add01Icon, Analytics01Icon, Delete01Icon }
sv import from ..services.maintenanceService { initialize_samples, list_tickets, list_slots, get_ticket_summary, create_ticket, transition_ticket_status, delete_ticket }

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
    has active_section: str = "Overview";
    has query: str = "";
    has status_filter: str = "All";
    has priority_filter: str = "All";
    has urgent_only: bool = False;
    has occupied_only: bool = False;
    has delete_ticket_id: int = 0;
    has deleting_ticket_id: int = 0;
    def handle_location(e: ChangeEvent) { location = e.target.value; }
    def handle_description(e: ChangeEvent) { description = e.target.value; }
    def handle_query(e: ChangeEvent) { query = e.target.value; }
    def handle_overview(e: MouseEvent) { active_section = "Overview"; }
    def handle_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; }
    def handle_report(e: MouseEvent) { active_section = "Report an Issue"; }
    def handle_schedule(e: MouseEvent) { active_section = "Repair Schedule"; }
    def handle_mission(e: MouseEvent) { active_section = "AI Mission Control"; }
    def filter_all(e: MouseEvent) { status_filter = "All"; priority_filter = "All"; urgent_only = False; query = ""; }
    def filter_open(e: MouseEvent) { status_filter = "Open"; urgent_only = False; query = ""; }
    def filter_progress(e: MouseEvent) { status_filter = "In Progress"; urgent_only = False; query = ""; }
    def filter_resolved(e: MouseEvent) { status_filter = "Resolved"; urgent_only = False; query = ""; }
    def reset_filters(e: MouseEvent) { status_filter = "All"; priority_filter = "All"; urgent_only = False; occupied_only = False; query = ""; }
    def filter_priority_all(e: MouseEvent) { priority_filter = "All"; urgent_only = False; }
    def filter_priority_urgent(e: MouseEvent) { priority_filter = "Urgent"; urgent_only = False; }
    def filter_priority_high(e: MouseEvent) { priority_filter = "High"; urgent_only = False; }
    def filter_priority_medium(e: MouseEvent) { priority_filter = "Medium"; urgent_only = False; }
    def filter_priority_low(e: MouseEvent) { priority_filter = "Low"; urgent_only = False; }
    def open_all_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; status_filter = "All"; priority_filter = "All"; urgent_only = False; query = ""; }
    def open_open_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; status_filter = "Open"; priority_filter = "All"; urgent_only = False; query = ""; }
    def open_progress_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; status_filter = "In Progress"; priority_filter = "All"; urgent_only = False; query = ""; }
    def open_resolved_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; status_filter = "Resolved"; priority_filter = "All"; urgent_only = False; query = ""; }
    def open_urgent_tickets(e: MouseEvent) { active_section = "Maintenance Tickets"; status_filter = "All"; priority_filter = "All"; urgent_only = True; query = ""; }
    def open_scheduled_slots(e: MouseEvent) { active_section = "Repair Schedule"; occupied_only = True; }
    def show_duplicate_unavailable(e: MouseEvent) { active_section = "Maintenance Tickets"; action_error = "Duplicate detection is unavailable until agent integration is implemented."; }
    def request_delete(ticket_id: int) { delete_ticket_id = ticket_id; }
    def cancel_delete(e: MouseEvent) { if deleting_ticket_id == 0 { delete_ticket_id = 0; } }

    async def confirm_delete(e: MouseEvent) {
        if delete_ticket_id < 1 or deleting_ticket_id != 0 { return; }
        ticket_id = delete_ticket_id;
        deleting_ticket_id = ticket_id;
        action_error = "";
        try {
            result = await delete_ticket(ticket_id, ticket_id);
            if result["ok"] as bool {
                delete_ticket_id = 0;
                success_message = "Ticket #" + str(ticket_id) + " deleted.";
                await refresh_graph();
            } else {
                action_error = result["message"] as str;
            }
        } except Exception as err {
            action_error = "Ticket deletion failed: " + str(err);
        }
        deleting_ticket_id = 0;
    }

    async def refresh_graph() {
        tickets = await list_tickets();
        slots = await list_slots();
        summary = await get_ticket_summary();
    }

    async def handle_submit(e: FormEvent) {
        e.preventDefault();
        if submitting { return; }
        location_value = location.strip();
        issue_value = description.strip();
        success_message = "";
        action_error = "";
        if len(location_value) < 2 or len(issue_value) < 5 {
            action_error = "Enter a meaningful location and issue description.";
            return;
        }
        submitting = True;
        try {
            result = await create_ticket(location_value, issue_value);
            if result["ok"] as bool {
                ticket_id = result["ticket_id"] as int;
                await refresh_graph();
                success_message = "Report saved as Ticket #" + str(ticket_id) + ".";
                location = "";
                description = "";
                active_section = "Maintenance Tickets";
            } else {
                action_error = result["message"] as str;
            }
        } except Exception as err {
            action_error = "Report submission failed: " + str(err);
        }
        submitting = False;
    }

    async def update_status(ticket_id: int) {
        action_error = "";
        updating_ticket = ticket_id;
        try {
            result = await transition_ticket_status(ticket_id);
            if result["updated"] as bool {
                await refresh_graph();
                success_message = "Ticket #" + str(ticket_id) + " status updated to " + (result["status"] as str) + ".";
            } else {
                action_error = "Ticket status could not be updated.";
            }
        } except Exception as err {
            action_error = "Status update failed: " + str(err);
        }
        updating_ticket = 0;
    }

    def matches(ticket: dict[str, any]) -> bool {
        state_ok = status_filter == "All" or ticket["status"] == status_filter;
        priority_ok = priority_filter == "All" or ticket["priority"] == priority_filter;
        urgency_ok = not urgent_only or ticket["priority"] == "Urgent";
        needle = query.strip().lower();
        text = ("Ticket #" + str(ticket["ticket_id"]) + " " + str(ticket["location"]) + " " + str(ticket["issue"])).lower();
        return state_ok and priority_ok and urgency_ok and (needle == "" or needle in text);
    }

    def slot_details(slot: dict[str, any]) -> str {
        detail: str = str(slot["slot_type"]) + " slot";
        if str(slot["occupied_by"]) != "" { detail = detail + " · " + str(slot["occupied_by"]); }
        return detail;
    }

    def next_status_label(status: str) -> str {
        label: str = "Mark In Progress";
        if status == "In Progress" { label = "Mark Resolved"; }
        return label;
    }

    async can with entry {
        try {
            await initialize_samples();
            await refresh_graph();
        } except Exception {
            load_error = "Campus operations data could not be loaded. Refresh to retry.";
        }
        loading = False;
    }

    open_count = 0;
    progress_count = 0;
    resolved_count = 0;
    urgent_count = 0;
    high_count = 0;
    medium_count = 0;
    low_count = 0;
    for ticket in tickets {
        if ticket["status"] == "Open" { open_count += 1; }
        elif ticket["status"] == "In Progress" { progress_count += 1; }
        elif ticket["status"] == "Resolved" { resolved_count += 1; }
        if ticket["priority"] == "Urgent" { urgent_count += 1; }
        elif ticket["priority"] == "High" { high_count += 1; }
        elif ticket["priority"] == "Medium" { medium_count += 1; }
        elif ticket["priority"] == "Low" { low_count += 1; }
    }
    active_class = "rounded-lg bg-primary/15 text-primary";
    quiet_class = "rounded-lg text-muted-foreground hover:bg-sidebar-accent hover:text-foreground";
    selected_ticket_location = "Unknown location";
    for ticket in tickets {
        if ticket["ticket_id"] == delete_ticket_id { selected_ticket_location = str(ticket["location"]); }
    }
    nav_class = lambda (section: str) -> str { return "flex items-center gap-3 px-3 py-2.5 text-left text-sm font-medium transition-colors " + (active_class if active_section == section else quiet_class); };

    return <main className="min-h-screen bg-slate-950 text-slate-100">
        <div className="mx-auto flex min-h-screen w-full max-w-[1600px] flex-col md:flex-row">
            <aside className="flex w-full shrink-0 flex-col border-b border-slate-800 bg-slate-950 p-4 md:sticky md:top-0 md:h-screen md:w-64 md:border-b-0 md:border-r md:p-5">
                <div className="flex items-center gap-3 px-2 py-2">
                    <div className="flex size-10 items-center justify-center rounded-xl bg-teal-400 text-slate-950"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-5" /></div>
                    <div><p className="font-semibold tracking-tight">{"FixFlow AI"}</p><p className="text-xs text-slate-400">{"Campus Operations"}</p></div>
                </div>
                <div className="mt-4 rounded-xl border border-slate-800 bg-slate-900/80 p-3"><p className="text-xs font-semibold uppercase tracking-wider text-teal-300">{"Jac-powered maintenance platform"}</p><p className="mt-2 text-sm font-medium">{"Smarter Campus. Faster Fixes."}</p></div>
                <nav aria-label="Main navigation" className="mt-5 grid grid-cols-2 gap-2 md:flex md:flex-1 md:flex-col">
                    <button type="button" onClick={handle_overview} className={nav_class("Overview")}><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-4" />{"Overview"}</button>
                    <button type="button" onClick={handle_tickets} className={nav_class("Maintenance Tickets")}><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-4" />{"Maintenance Tickets"}</button>
                    <button type="button" onClick={handle_report} className={nav_class("Report an Issue")}><HugeiconsIcon icon={Add01Icon} strokeWidth={2} className="size-4" />{"Report an Issue"}</button>
                    <button type="button" onClick={handle_schedule} className={nav_class("Repair Schedule")}><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-4" />{"Repair Schedule"}</button>
                    <button type="button" onClick={handle_mission} className={nav_class("AI Mission Control")}><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" />{"AI Mission Control"}</button>
                </nav>
                <div className="mt-4 hidden rounded-xl border border-slate-800 bg-slate-900 p-3 md:block"><p className="text-xs text-slate-400">{"Campus Operations"}</p><p className="mt-1 flex items-center gap-2 text-sm"><span className="size-2 rounded-full bg-emerald-400" />{"Systems online"}</p></div>
            </aside>

            <section className="min-w-0 flex-1">
                <header className="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 border-b border-slate-800 bg-slate-950/95 px-4 py-4 backdrop-blur sm:px-6 lg:px-8">
                    <div><p className="text-xs font-medium text-teal-300">{"CAMPUS OPERATIONS COMMAND CENTER"}</p><h1 className="mt-1 text-xl font-semibold tracking-tight sm:text-2xl">{active_section}</h1></div>
                    <div className="flex items-center gap-3"><span className="hidden rounded-full border border-slate-700 bg-slate-900 px-3 py-1.5 text-xs text-slate-300 sm:inline-flex">{"Campus Operations"}</span><span className="rounded-lg border border-slate-800 bg-slate-900 px-3 py-2 text-sm"><span className="text-slate-400">{"Live tickets "}</span><strong className="tabular-nums text-teal-300">{str(summary["total_tickets"] if summary else 0)}</strong></span><Button type="button" onClick={handle_report} className="bg-teal-400 text-slate-950 hover:bg-teal-300"><HugeiconsIcon icon={Add01Icon} strokeWidth={2} className="size-4" />{"New Report"}</Button></div>
                </header>

                <div className="flex flex-col gap-6 p-4 sm:p-6 lg:p-8">
                    {if load_error != "" { <p className="rounded-lg border border-rose-900 bg-rose-950/40 p-3 text-sm text-rose-300" role="alert">{load_error}</p> }}
                    {if success_message != "" { <p className="rounded-lg border border-emerald-900 bg-emerald-950/40 p-3 text-sm text-emerald-300" role="status">{success_message}</p> }}
                    {if action_error != "" { <p className="rounded-lg border border-rose-900 bg-rose-950/40 p-3 text-sm text-rose-300" role="alert">{action_error}</p> }}
                    {if delete_ticket_id > 0 {
                        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4" role="presentation">
                            <section role="alertdialog" aria-modal="true" aria-labelledby="delete-dialog-title" className="w-full max-w-md rounded-2xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
                                <h2 id="delete-dialog-title" className="text-lg font-semibold">{"Delete maintenance ticket?"}</h2>
                                <p className="mt-3 text-sm text-slate-300">{"Ticket #" + str(delete_ticket_id) + " · " + selected_ticket_location}</p>
                                <p className="mt-2 text-sm text-rose-300">{"This action cannot be undone. Any assigned slot will be released."}</p>
                                <div className="mt-5 flex justify-end gap-2">
                                    <Button type="button" variant="outline" disabled={deleting_ticket_id != 0} onClick={cancel_delete} className="border-slate-700 bg-slate-950 text-slate-200">{"Cancel"}</Button>
                                    <Button type="button" variant="destructive" disabled={deleting_ticket_id != 0} onClick={confirm_delete}>{"Delete Ticket" if deleting_ticket_id == 0 else "Deleting…"}</Button>
                                </div>
                            </section>
                        </div>
                    }}

                    {if active_section == "Overview" {
                        <section className="flex flex-col gap-6">
                            <div className="flex flex-wrap items-end justify-between gap-3"><div><h2 className="text-2xl font-semibold tracking-tight">{"Campus overview"}</h2><p className="mt-1 text-sm text-slate-400">{"Live maintenance activity from the shared campus graph."}</p></div><span className="rounded-full border border-slate-800 bg-slate-900 px-3 py-1.5 text-xs text-slate-400">{"Graph data · live"}</span></div>
                            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
                                <button type="button" onClick={open_all_tickets} aria-label="View all tickets" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-teal-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Total Tickets"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(summary["total_tickets"] if summary else 0) if not loading else "…"}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-teal-400/10 text-teal-300"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={open_open_tickets} aria-label="View open tickets" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-amber-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Open Tickets"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(open_count)}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-amber-400/10 text-amber-300"><HugeiconsIcon icon={Alert01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={open_progress_tickets} aria-label="View tickets in progress" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-cyan-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"In Progress"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(progress_count)}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-cyan-400/10 text-cyan-300"><HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={open_resolved_tickets} aria-label="View resolved tickets" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-emerald-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Resolved"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(resolved_count)}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-emerald-400/10 text-emerald-300"><HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={open_urgent_tickets} aria-label="View urgent hazard tickets" aria-pressed={urgent_only} className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-rose-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Urgent Hazards"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(urgent_count)}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-rose-400/10 text-rose-300"><HugeiconsIcon icon={Alert01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={open_scheduled_slots} aria-label="View occupied repair slots" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-teal-400/50 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-300"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Scheduled Repairs"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(summary["scheduled_repairs"] if summary else 0)}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-teal-400/10 text-teal-300"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                                <button type="button" onClick={show_duplicate_unavailable} aria-label="Merged duplicates, unavailable until agent integration" className="group cursor-pointer rounded-2xl border border-slate-800 bg-slate-900 text-left text-slate-100 shadow-sm transition-colors hover:border-slate-600 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400"><div className="flex items-center justify-between gap-3 p-4"><div><p className="text-xs text-slate-400">{"Merged Duplicates"}</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(summary["merged_duplicates"] if summary else 0)}</p><p className="mt-1 text-[11px] text-slate-500">{"Unavailable · agent pending"}</p></div><span className="flex size-10 items-center justify-center rounded-xl bg-slate-800 text-slate-300"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-5" /></span></div></button>
                            </div>
                            <div className="grid gap-5 xl:grid-cols-5">
                                <Card className="border-slate-800 bg-slate-900 text-slate-100 xl:col-span-3"><CardHeader><CardTitle>{"Recent Maintenance Issues"}</CardTitle><CardDescription className="text-slate-400">{"Current tickets from the campus graph."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">{if loading { <p className="text-sm text-slate-400">{"Loading campus tickets…"}</p> }}{if not loading and len(tickets) == 0 { <Empty className="border border-dashed border-slate-700 bg-slate-950 text-slate-200"><EmptyHeader><EmptyMedia variant="icon"><HugeiconsIcon icon={File01Icon} strokeWidth={2} /></EmptyMedia><EmptyTitle>{"No maintenance reports"}</EmptyTitle><EmptyDescription className="text-slate-400">{"Submit a campus issue to start the ticket queue."}</EmptyDescription></EmptyHeader></Empty> }}{for ticket in tickets { <article key={str(ticket["ticket_id"])} className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-800 bg-slate-950 p-4"><div className="min-w-0"><p className="font-medium">{"#" + str(ticket["ticket_id"]) + " · " + str(ticket["location"])}</p><p className="mt-1 truncate text-sm text-slate-400">{str(ticket["issue"])}</p><p className="mt-2 text-xs text-slate-500">{str(ticket["category"]) + " · " + str(ticket["priority"]) + " · " + str(ticket["scheduled_time"])}</p></div><span className="rounded-full border border-slate-700 bg-slate-900 px-2.5 py-1 text-xs text-slate-300">{str(ticket["status"])}</span></article> }}</CardContent></Card>
                                <div className="flex flex-col gap-5 xl:col-span-2"><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardHeader><CardTitle>{"Priority Breakdown"}</CardTitle><CardDescription className="text-slate-400">{"Counts derived from stored tickets."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">{for (label, count, color) in [("Urgent", urgent_count, "bg-rose-400"), ("High", high_count, "bg-orange-400"), ("Medium", medium_count, "bg-amber-300"), ("Low", low_count, "bg-cyan-300")] { <div key={label} className="flex items-center gap-3"><span className={"size-2.5 rounded-full " + color} /><span className="flex-1 text-sm text-slate-300">{label}</span><span className="text-sm font-semibold tabular-nums">{str(count)}</span></div> }}</CardContent></Card><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardHeader><CardTitle>{"Upcoming Repair Schedule"}</CardTitle><CardDescription className="text-slate-400">{"Real technician time slots."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">{for slot in slots { <div key={str(slot["slot_id"])} className="flex items-center justify-between gap-2 rounded-lg border border-slate-800 bg-slate-950 p-3"><div><p className="text-sm font-medium">{str(slot["label"])}</p><p className="mt-1 text-xs text-slate-500">{slot_details(slot)}</p></div><span className={"rounded-full px-2 py-1 text-xs " + ("bg-emerald-400/10 text-emerald-300" if slot["is_available"] else "bg-slate-800 text-slate-300")}>{"Available" if slot["is_available"] else "Occupied"}</span></div> }}</CardContent></Card></div>
                            </div>
                            <div className="grid grid-cols-1 gap-3 sm:grid-cols-3"><Button type="button" onClick={handle_report} className="bg-teal-400 text-slate-950 hover:bg-teal-300"><HugeiconsIcon icon={Add01Icon} strokeWidth={2} />{"New Maintenance Report"}</Button><Button type="button" variant="outline" onClick={handle_tickets} className="border-slate-700 bg-slate-900 text-slate-100 hover:bg-slate-800">{"View All Tickets"}</Button><Button type="button" variant="outline" onClick={handle_schedule} className="border-slate-700 bg-slate-900 text-slate-100 hover:bg-slate-800">{"View Repair Schedule"}</Button></div>
                        </section>
                    }}

                    {if active_section == "Maintenance Tickets" {
                        <section className="flex flex-col gap-5"><div><h2 className="text-2xl font-semibold tracking-tight">{"Maintenance Tickets"}</h2><p className="mt-1 text-sm text-slate-400">{"Search and manage real campus reports."}</p></div><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardContent className="flex flex-col gap-4 p-4"><div className="relative"><HugeiconsIcon icon={Search01Icon} strokeWidth={2} className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-slate-500" /><Input value={query} onChange={handle_query} placeholder="Search ID, location, or issue" className="border-slate-700 bg-slate-950 pl-9 text-slate-100 placeholder:text-slate-500" /></div><div className="flex flex-wrap gap-2"><span className="self-center pr-1 text-xs text-slate-500">{"Status"}</span><Button size="sm" variant="outline" onClick={reset_filters} className="border-slate-700 bg-slate-950 text-slate-200">{"Reset All"}</Button><Button size="sm" variant="outline" aria-pressed={status_filter == "All" and not urgent_only} onClick={filter_all} className="border-slate-700 bg-slate-950 text-slate-200">{"All"}</Button><Button size="sm" variant="outline" aria-pressed={status_filter == "Open" and not urgent_only} onClick={filter_open} className="border-slate-700 bg-slate-950 text-slate-200">{"Open"}</Button><Button size="sm" variant="outline" aria-pressed={status_filter == "In Progress"} onClick={filter_progress} className="border-slate-700 bg-slate-950 text-slate-200">{"In Progress"}</Button><Button size="sm" variant="outline" aria-pressed={status_filter == "Resolved"} onClick={filter_resolved} className="border-slate-700 bg-slate-950 text-slate-200">{"Resolved"}</Button></div><div className="flex flex-wrap gap-2"><span className="self-center pr-1 text-xs text-slate-500">{"Priority"}</span><Button size="sm" variant="outline" aria-pressed={priority_filter == "All"} onClick={filter_priority_all} className="border-slate-700 bg-slate-950 text-slate-200">{"All"}</Button><Button size="sm" variant="outline" aria-pressed={priority_filter == "Urgent" or urgent_only} onClick={filter_priority_urgent} className="border-slate-700 bg-slate-950 text-slate-200">{"Urgent"}</Button><Button size="sm" variant="outline" aria-pressed={priority_filter == "High"} onClick={filter_priority_high} className="border-slate-700 bg-slate-950 text-slate-200">{"High"}</Button><Button size="sm" variant="outline" aria-pressed={priority_filter == "Medium"} onClick={filter_priority_medium} className="border-slate-700 bg-slate-950 text-slate-200">{"Medium"}</Button><Button size="sm" variant="outline" aria-pressed={priority_filter == "Low"} onClick={filter_priority_low} className="border-slate-700 bg-slate-950 text-slate-200">{"Low"}</Button></div><p className="text-xs text-slate-500">{str(len([ticket for ticket in tickets if matches(ticket)])) + " matching tickets"}</p></CardContent></Card><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardContent className="flex flex-col gap-3 p-4">{if loading { <p className="text-sm text-slate-400">{"Loading tickets…"}</p> }}{for ticket in tickets { if matches(ticket) { <article key={str(ticket["ticket_id"])} className="rounded-xl border border-slate-800 bg-slate-950 p-4"><div className="flex flex-wrap items-start justify-between gap-3"><div className="min-w-0"><p className="font-semibold">{"Ticket #" + str(ticket["ticket_id"]) + " · " + str(ticket["location"])}</p><p className="mt-1 text-sm text-slate-300">{str(ticket["issue"])}</p><div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-500"><span>{str(ticket["category"])}</span><span>{str(ticket["priority"]) + " priority"}</span><span>{str(ticket["report_count"]) + " report"}</span><span>{str(ticket["scheduled_time"])}</span></div></div><div className="flex items-center gap-2"><span className="rounded-full border border-slate-700 px-2.5 py-1 text-xs">{str(ticket["status"])}</span><Button type="button" size="sm" variant="outline" aria-label={"Delete ticket #" + str(ticket["ticket_id"]) + " at " + str(ticket["location"])} disabled={deleting_ticket_id != 0} onClick={lambda { request_delete(ticket["ticket_id"] as int); }} className="border-rose-900/70 bg-slate-900 text-rose-300 hover:bg-rose-950"><HugeiconsIcon icon={Delete01Icon} strokeWidth={2} className="size-4" /><span className="sr-only">{"Delete ticket"}</span></Button></div></div><div className="mt-4">{if str(ticket["status"]) != "Resolved" { <Button type="button" size="sm" variant="outline" disabled={updating_ticket == (ticket["ticket_id"] as int)} onClick={lambda { update_status(ticket["ticket_id"] as int); }} className="border-slate-700 bg-slate-900 text-slate-100">{next_status_label(str(ticket["status"]))}</Button> }}</div></article> } }}</CardContent></Card></section>
                    }}

                    {if active_section == "Report an Issue" {
                        <section className="mx-auto flex w-full max-w-3xl flex-col gap-5"><div><p className="text-xs font-semibold uppercase tracking-wider text-teal-300">{"CAMPUS SERVICE REQUEST"}</p><h2 className="mt-2 text-2xl font-semibold tracking-tight">{"Report a maintenance issue"}</h2><p className="mt-1 text-sm text-slate-400">{"Share a location and a clear description. New tickets begin unscheduled and awaiting review."}</p></div><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardHeader><CardTitle>{"New maintenance report"}</CardTitle><CardDescription className="text-slate-400">{"Your report is stored in the shared campus graph."}</CardDescription></CardHeader><CardContent><form onSubmit={handle_submit} className="flex flex-col gap-5"><FieldGroup><Field><FieldLabel htmlFor="location" className="text-slate-200">{"Location"}</FieldLabel><Input id="location" value={location} onChange={handle_location} placeholder="e.g. Engineering Workshop" className="border-slate-700 bg-slate-950 text-slate-100 placeholder:text-slate-500" /></Field><Field><FieldLabel htmlFor="description" className="text-slate-200">{"Issue Description"}</FieldLabel><Textarea id="description" value={description} onChange={handle_description} placeholder="Describe what needs attention" className="min-h-32 border-slate-700 bg-slate-950 text-slate-100 placeholder:text-slate-500" /></Field></FieldGroup><Button type="submit" disabled={submitting} className="bg-teal-400 text-slate-950 hover:bg-teal-300">{"Submit Report" if not submitting else "Saving report…"}</Button></form></CardContent></Card><p className="text-xs text-slate-500">{"No AI classification or schedule is assigned at submission."}</p></section>
                    }}

                    {if active_section == "Repair Schedule" {
                        <section className="flex flex-col gap-5"><div className="flex flex-wrap items-end justify-between gap-3"><div><h2 className="text-2xl font-semibold tracking-tight">{"Repair Schedule"}</h2><p className="mt-1 text-sm text-slate-400">{"Technician time slots stored in the campus graph."}</p>{if occupied_only { <p className="mt-2 text-xs text-teal-300">{"Showing occupied repair slots"}</p> }}</div><div className="flex gap-2"><Button type="button" size="sm" variant="outline" onClick={reset_filters} className="border-slate-700 bg-slate-900 text-slate-200">{"Show all slots"}</Button><Button type="button" size="sm" variant="outline" onClick={open_scheduled_slots} className="border-slate-700 bg-slate-900 text-slate-200">{"Show occupied only"}</Button></div></div><div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">{for slot in slots { if not occupied_only or str(slot["occupied_by"]) != "" { <Card key={str(slot["slot_id"])} className="border-slate-800 bg-slate-900 text-slate-100"><CardContent className="flex flex-col gap-5 p-5"><div className="flex items-start justify-between gap-3"><span className="flex size-10 items-center justify-center rounded-xl bg-teal-400/10 text-teal-300"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-5" /></span><span className={"rounded-full px-2.5 py-1 text-xs " + ("bg-emerald-400/10 text-emerald-300" if slot["is_available"] else "bg-slate-800 text-slate-300")}>{"Available" if slot["is_available"] else "Occupied"}</span></div><div><h3 className="font-semibold">{str(slot["label"])}</h3><p className="mt-1 text-sm text-slate-400">{slot_details(slot)}</p></div></CardContent></Card> } }}</div></section>
                    }}

                    {if active_section == "AI Mission Control" {
                        <section className="flex flex-col gap-5"><div><p className="text-xs font-semibold uppercase tracking-wider text-teal-300">{"SUPERVISED AUTOMATION"}</p><h2 className="mt-2 text-2xl font-semibold tracking-tight">{"AI Mission Control"}</h2><p className="mt-1 text-sm text-slate-400">{"A transparent workspace for future campus operations agents."}</p></div><Card className="border-slate-800 bg-slate-900 text-slate-100"><CardContent className="flex flex-col gap-5 p-6"><div className="flex size-12 items-center justify-center rounded-2xl bg-teal-400/10 text-teal-300"><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-6" /></div><div><h3 className="text-lg font-semibold">{"Agent integration pending"}</h3><p className="mt-2 max-w-2xl text-sm leading-relaxed text-slate-400">{"Safety assessment, duplicate detection, priority analysis, and automatic repair scheduling will appear here when a real Jac agent is connected. No agent actions or AI results are currently being reported."}</p></div></CardContent></Card><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{for title in ["Safety Assessment", "Duplicate Detection", "Priority Analysis", "Repair Scheduling"] { <Card key={title} className="border-slate-800 bg-slate-900 text-slate-100"><CardContent className="flex flex-col gap-3 p-4"><span className="flex size-9 items-center justify-center rounded-lg bg-slate-800 text-slate-400"><HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-4" /></span><p className="font-medium">{title}</p><p className="text-xs text-slate-500">{"Pending agent integration"}</p></CardContent></Card> }}</div></section>
                    }}
                </div>
            </section>
        </div>
    </main>;
}
