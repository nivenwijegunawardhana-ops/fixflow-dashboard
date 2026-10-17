import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.field { Field, FieldLabel, FieldGroup }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.button { Button }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { DashboardSquare01Icon, File01Icon, Alert01Icon, Calendar01Icon }

def:pub MaintenanceDashboard() -> JsxElement {
    has location: str = "";
    has description: str = "";
    def handle_location(e: ChangeEvent) { location = e.target.value; }
    def handle_description(e: ChangeEvent) { description = e.target.value; }
    def handle_submit(e: FormEvent) { e.preventDefault(); }

    return <main className="min-h-screen bg-muted/40 px-4 py-8 sm:px-6 lg:py-12">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <header className="flex flex-wrap items-center gap-4 rounded-2xl border bg-card px-5 py-5 shadow-sm sm:px-7">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                    <HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-6" />
                </div>
                <div className="flex flex-col gap-1">
                    <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">{"FixFlow AI"}</h1>
                    <p className="text-sm text-muted-foreground">{"Campus Maintenance Assistant"}</p>
                </div>
                <div className="ml-auto hidden items-center gap-2 rounded-full border bg-background px-3 py-1.5 text-xs font-medium text-muted-foreground sm:flex">
                    <span className="size-2 rounded-full bg-primary" />{"Campus operations"}
                </div>
            </header>

            <section className="flex flex-col gap-4" aria-label="Maintenance summary">
                <div className="flex flex-col gap-1">
                    <h2 className="text-xl font-semibold tracking-tight">{"Maintenance overview"}</h2>
                    <p className="text-sm text-muted-foreground">{"A clear view of campus reports and repair activity."}</p>
                </div>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    <Card className="shadow-sm transition-shadow hover:shadow-md">
                        <CardContent className="flex flex-col gap-5 pt-5">
                            <div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Total Tickets"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-4" /></div></div>
                            <span className="text-3xl font-semibold tracking-tight tabular-nums">{"0"}</span>
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md">
                        <CardContent className="flex flex-col gap-5 pt-5">
                            <div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Merged Duplicates"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-4" /></div></div>
                            <span className="text-3xl font-semibold tracking-tight tabular-nums">{"0"}</span>
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md">
                        <CardContent className="flex flex-col gap-5 pt-5">
                            <div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Urgent Hazards"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Alert01Icon} strokeWidth={2} className="size-4" /></div></div>
                            <span className="text-3xl font-semibold tracking-tight tabular-nums">{"0"}</span>
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm transition-shadow hover:shadow-md">
                        <CardContent className="flex flex-col gap-5 pt-5">
                            <div className="flex items-center justify-between"><span className="text-sm font-medium text-muted-foreground">{"Scheduled Repairs"}</span><div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-4" /></div></div>
                            <span className="text-3xl font-semibold tracking-tight tabular-nums">{"0"}</span>
                        </CardContent>
                    </Card>
                </div>
            </section>

            <div className="grid grid-cols-1 items-start gap-5 lg:grid-cols-5">
                <Card className="shadow-sm lg:col-span-2">
                    <CardHeader>
                        <CardTitle>{"Report a Problem"}</CardTitle>
                        <CardDescription>{"Let the campus team know what needs attention."}</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form onSubmit={handle_submit} className="flex flex-col gap-5">
                            <FieldGroup>
                                <Field>
                                    <FieldLabel htmlFor="location">{"Location"}</FieldLabel>
                                    <Input id="location" value={location} onChange={handle_location} placeholder="e.g. Science Building, room 204" className="h-10" />
                                </Field>
                                <Field>
                                    <FieldLabel htmlFor="description">{"Issue Description"}</FieldLabel>
                                    <Textarea id="description" value={description} onChange={handle_description} placeholder="Describe the maintenance issue" className="min-h-28 resize-y" />
                                </Field>
                            </FieldGroup>
                            <Button type="submit" className="h-10 w-full shadow-sm">{"Submit Report"}</Button>
                        </form>
                    </CardContent>
                </Card>

                <Card className="shadow-sm lg:col-span-3">
                    <CardHeader>
                        <CardTitle>{"Recent Maintenance Tickets"}</CardTitle>
                        <CardDescription>{"The latest reports from around campus."}</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Empty className="rounded-xl border border-dashed bg-muted/20 py-10">
                            <EmptyHeader>
                                <EmptyMedia variant="icon"><HugeiconsIcon icon={File01Icon} strokeWidth={2} /></EmptyMedia>
                                <EmptyTitle>{"No reports yet"}</EmptyTitle>
                                <EmptyDescription>{"Submitted maintenance reports will appear here."}</EmptyDescription>
                            </EmptyHeader>
                        </Empty>
                    </CardContent>
                </Card>
            </div>
            <footer className="flex justify-center border-t pt-5 text-xs text-muted-foreground">{"Campus Maintenance Assistant"}</footer>
        </div>
    </main>;
}
