# Grafana Architecture Documentation

## Overview

Grafana is an open-source platform for monitoring and observability that allows users to query, visualize, alert on, and understand metrics from various data sources. The application is built with a hybrid architecture combining a Go backend with a TypeScript/React frontend.

## High-Level Architecture

Grafana follows a client-server architecture with the following layers:

```
┌─────────────────────────────────────────────────────┐
│            Frontend (TypeScript/React)              │
│  - Dashboard Rendering                              │
│  - Panel Visualizations                             │
│  - Query Editors                                    │
│  - Configuration UI                                 │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP/WebSocket
┌──────────────────┴──────────────────────────────────┐
│              Backend (Go)                           │
│  - HTTP Server                                      │
│  - API Endpoints                                    │
│  - Authentication & Authorization                   │
│  - Data Source Proxy                                │
│  - Query Engine                                     │
│  - Alerting Engine                                  │
│  - Plugin Management                                │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────┐
│          Data Sources & Plugins                     │
│  - Prometheus, Loki, InfluxDB, MySQL, etc.         │
│  - Custom Plugins                                   │
└─────────────────────────────────────────────────────┘
```

## Backend Architecture

### Core Components

#### 1. Server (`pkg/server/`)

The `Server` struct is the core component responsible for managing the lifecycle of all services.

**Key responsibilities:**
- Initializes all background services
- Manages HTTP server lifecycle
- Coordinates graceful shutdown
- Handles provisioning of resources

**Main entry point:**
- `pkg/cmd/grafana-server/main.go` - Server entry point
- `pkg/cmd/grafana-cli/main.go` - CLI tool entry point

#### 2. HTTP Server (`pkg/api/`)

The `HTTPServer` struct handles all HTTP requests and routing.

**Key components:**
- Route registration and middleware configuration
- API endpoint implementations for:
  - Dashboards (`dashboard.go`)
  - Data sources (`datasources.go`)
  - Users and organizations (`user.go`, `org.go`)
  - Queries (`ds_query.go`)
  - Annotations (`annotations.go`)
  - Alerts (`alerting.go`)
  - Plugins (`plugins.go`)

**Architecture pattern:**
- Uses dependency injection via Wire
- Middleware-based request processing
- Context-based authentication and authorization

#### 3. Services (`pkg/services/`)

Grafana uses a service-oriented architecture with specialized services for different domains:

**Core Services:**
- **Authentication/Authorization:**
  - `accesscontrol/` - Role-based access control (RBAC)
  - `authn/` - Authentication services
  - `authz/` - Authorization services
  - `apikey/` - API key management
  - `serviceaccounts/` - Service account management

- **Data Management:**
  - `datasources/` - Data source configuration and management
  - `datasourceproxy/` - Proxy for data source requests
  - `query/` - Query execution engine
  - `caching/` - Query result caching

- **Dashboard & Visualization:**
  - `dashboards/` - Dashboard CRUD operations
  - `folder/` - Folder management
  - `dashboardsnapshots/` - Dashboard snapshot functionality
  - `annotations/` - Annotation management
  - `librarypanels/` - Reusable library panels

- **Alerting:**
  - `ngalert/` - Next-generation alerting engine
  - Alert rule evaluation
  - Notification routing and delivery

- **Plugin System:**
  - `pluginsintegration/` - Plugin integration services
  - Plugin loading and lifecycle management
  - Plugin settings and configuration

- **User Management:**
  - `user/` - User CRUD operations
  - `org/` - Organization management
  - `team/` - Team management
  - `preference/` - User preferences

#### 4. Data Source Integration (`pkg/tsdb/`)

Built-in data source implementations:
- Prometheus (`prometheus/`)
- Loki (`loki/`)
- InfluxDB (`influxdb/`)
- MySQL (`mysql/`)
- PostgreSQL (`grafana-postgresql-datasource/`)
- CloudWatch (`cloudwatch/`)
- Azure Monitor (`azuremonitor/`)
- And many more...

Each data source implements a query interface and handles:
- Query parsing and execution
- Result formatting
- Authentication
- Rate limiting

#### 5. Plugin System (`pkg/plugins/`)

Grafana's extensibility is built on a plugin architecture:

**Plugin types:**
- **Data source plugins** - Connect to external data sources
- **Panel plugins** - Custom visualization types
- **App plugins** - Full applications within Grafana

**Plugin management:**
- Dynamic loading and initialization
- Sandboxed execution
- Version management
- Configuration storage

### Backend Design Patterns

#### Dependency Injection
Grafana uses [Wire](https://github.com/google/wire) for compile-time dependency injection. Service dependencies are declared in `wire.go` files throughout the codebase.

#### Service Registry
Services implement interfaces and are registered in a central registry (`pkg/registry/`), allowing for:
- Ordered initialization
- Background service management
- Clean shutdown handling

#### Event Bus
An event bus (`pkg/bus/`) enables decoupled communication between services:
- Query handlers
- Command handlers
- Event publishing/subscribing

## Frontend Architecture

### Core Technologies

- **Framework:** React with TypeScript
- **State Management:** Redux (legacy), React hooks, and Scene library
- **Build System:** Webpack with custom configuration
- **Styling:** Emotion CSS-in-JS and SASS
- **Monorepo:** Yarn workspaces with Nx

### Frontend Structure

#### 1. Application Core (`public/app/`)

**Main components:**
- `core/` - Core application services and utilities
- `features/` - Feature-specific code organized by domain
- `plugins/` - Plugin implementations
- `types/` - TypeScript type definitions
- `routes/` - Application routing

#### 2. Packages (`packages/`)

Reusable packages published to npm:

- **`@grafana/data`** - Core data model and utilities
  - Data frames and field types
  - Time range utilities
  - Data transformations
  - Plugin base classes

- **`@grafana/ui`** - UI component library
  - Design system components
  - Form components
  - Visualization components

- **`@grafana/runtime`** - Runtime services
  - Backend service client
  - Location service
  - Feature toggle access

- **`@grafana/schema`** - Dashboard and panel schemas
- **`@grafana/e2e-selectors`** - Testing selectors
- **Plugin-specific packages** for built-in plugins

#### 3. Key Frontend Classes and Models

##### DashboardModel (`public/app/features/dashboard/state/DashboardModel.ts`)

The central model for dashboards:

```typescript
export class DashboardModel implements TimeModel {
  id: any;
  uid: any;
  title: string;
  panels: PanelModel[];
  templating: { list: any[] };
  annotations: { list: AnnotationQuery[] };
  time: any;
  timepicker: any;
  refresh?: string;
  // ... many more properties
}
```

**Responsibilities:**
- Dashboard state management
- Panel orchestration
- Variable management
- Time range handling
- Event coordination

##### PanelModel (`public/app/features/dashboard/state/PanelModel.ts`)

Represents individual panels within dashboards:

```typescript
export class PanelModel implements IPanelModel {
  id: number;
  type: string;
  title: string;
  gridPos: GridPos;
  targets: DataQuery[];
  datasource?: DataSourceRef;
  options: any;
  fieldConfig: FieldConfigSource;
  // ... more properties
}
```

**Responsibilities:**
- Panel configuration
- Query execution
- Data transformation
- Plugin integration

##### PanelPlugin (`packages/grafana-data/src/panel/PanelPlugin.ts`)

Base class for panel plugins:

```typescript
export class PanelPlugin<TOptions = any> extends GrafanaPlugin<PanelPluginMeta> {
  panel: ComponentType<PanelProps<TOptions>>;
  setPanelOptions(builder: PanelOptionsEditorBuilder<TOptions>): this;
  setDataSupport(support: Partial<PanelPluginDataSupport>): this;
  // ... more methods
}
```

Provides the framework for creating custom visualizations.

##### DataSourcePlugin (`packages/grafana-data/src/types/datasource.ts`)

Base class for data source plugins:

```typescript
export class DataSourcePlugin<
  DSType extends DataSourceApi<TQuery, TOptions>,
  TQuery extends DataQuery = DataQuery,
  TOptions extends DataSourceJsonData = DataSourceJsonData
> extends GrafanaPlugin<DataSourcePluginMeta<TOptions>> {
  DataSourceClass: DataSourceConstructor<DSType, TQuery, TOptions>;
  setConfigEditor(editor: ComponentType<...>): this;
  setQueryEditor(QueryEditor: ComponentType<...>): this;
  // ... more methods
}
```

### Frontend Data Flow

```
┌─────────────────────────────────────────────────────┐
│  1. User Interaction (Dashboard/Panel)              │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  2. Query Construction                              │
│     - PanelQueryRunner                              │
│     - DataQueryRequest creation                     │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  3. Backend Request                                 │
│     - BackendSrv (HTTP client)                      │
│     - Request queue management                      │
│     - Request cancellation                          │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  4. Backend Processing                              │
│     - Query service                                 │
│     - Data source proxy                             │
│     - Plugin execution                              │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  5. Data Transformation                             │
│     - Field overrides                               │
│     - Data transformers                             │
│     - Threshold calculation                         │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  6. Visualization Rendering                         │
│     - Panel component                               │
│     - Chart libraries                               │
│     - Theme application                             │
└─────────────────────────────────────────────────────┘
```

## Data Model

### Core Data Structures

#### DataQuery
Base interface for all queries:
```typescript
export interface DataQuery {
  refId: string;
  hide?: boolean;
  queryType?: string;
  datasource?: DataSourceRef;
}
```

#### DataFrame
The fundamental data structure for time series and tabular data:
```typescript
export interface DataFrame {
  name?: string;
  fields: Field[];
  length: number;
  meta?: QueryResultMeta;
}
```

#### Field
Represents a column of data:
```typescript
export interface Field {
  name: string;
  type: FieldType;
  config: FieldConfig;
  values: Vector;
  labels?: Labels;
}
```

### Request/Response Flow

1. **DataQueryRequest** - Sent from frontend to backend
2. **Backend processing** - Query service routes to appropriate data source
3. **DataQueryResponse** - Contains DataFrames with results
4. **PanelData** - Enhanced with metadata, timing, and error information
5. **Visualization** - Rendered by panel plugin

## Plugin Architecture

### Plugin Types and Lifecycle

#### 1. Data Source Plugins
- Implement `DataSourceApi` interface
- Handle query execution
- Manage authentication
- Support annotations and variables

#### 2. Panel Plugins
- Extend `PanelPlugin` class
- Implement visualization component
- Define options and field config
- Support data transformations

#### 3. App Plugins
- Provide standalone applications
- Can include pages, panels, and data sources
- Custom navigation and routing

### Plugin Loading

**Backend:**
1. Scan plugin directories
2. Parse `plugin.json` metadata
3. Load plugin executable (for backend plugins)
4. Register plugin with plugin manager

**Frontend:**
1. Fetch plugin metadata from backend
2. Lazy load plugin JavaScript
3. Initialize plugin class
4. Register with plugin registry

## Build and Deployment

### Build Process

**Frontend:**
```bash
# Install dependencies
yarn install --immutable

# Build for production
yarn build

# Development mode with hot reload
yarn start
```

**Backend:**
```bash
# Build Go binary
make build-go

# Run server
make run
```

### Docker Build

The multi-stage Dockerfile:
1. **JS Builder** - Builds frontend assets
2. **Go Builder** - Compiles backend binary
3. **Final Image** - Combines artifacts with runtime dependencies

Environment paths:
- Config: `/etc/grafana/grafana.ini`
- Data: `/var/lib/grafana`
- Logs: `/var/log/grafana`
- Plugins: `/var/lib/grafana/plugins`

## Alerting System

### Next-Generation Alerting (`pkg/services/ngalert/`)

**Components:**
- **Rule Evaluation** - Scheduled query execution
- **State Management** - Alert state tracking
- **Notification Routing** - Multi-channel delivery
- **Silence Management** - Alert suppression
- **Remote Alertmanager** - External alertmanager integration

**Alert Rule Flow:**
```
Query → Evaluation → State Change → Route → Notify
```

## Authentication and Authorization

### Authentication (`pkg/services/authn/`)
- Basic authentication
- OAuth integration (Google, GitHub, Azure AD, etc.)
- LDAP/Active Directory
- SAML
- JWT
- API keys and service accounts

### Authorization (`pkg/services/accesscontrol/`)
- Role-based access control (RBAC)
- Fine-grained permissions
- Resource-level access control
- Organization and team-based isolation

## Database Layer

### SQL Store (`pkg/services/sqlstore/`)
- Supports MySQL, PostgreSQL, SQLite
- Migration system for schema updates
- Query builders and ORM-style access

### Unified Storage (`pkg/storage/`)
- New storage layer for Kubernetes-native deployments
- Resource-based API
- Supports custom backends

## API Server

### REST API (`pkg/api/`)
All dashboard operations, data source configuration, and user management exposed via REST endpoints.

### OpenAPI Specification
- `public/openapi3.json` - API specification
- Swagger UI available at `/swagger`

## Testing Strategy

- **Backend:** Go standard testing with testify
- **Frontend:** Jest for unit tests, Playwright for E2E tests
- **E2E:** Cypress (legacy) and Playwright (new)
- **Integration:** Full stack tests in `e2e/` directory

## Configuration

### Configuration Sources
1. Configuration file (`conf/defaults.ini`, custom `grafana.ini`)
2. Environment variables (override config)
3. Command-line flags
4. Provisioning files (`conf/provisioning/`)

### Provisioning
Declarative configuration for:
- Data sources
- Dashboards
- Alert rules
- Notification channels

## Performance Considerations

### Caching Strategy
- Query result caching (in-memory and distributed)
- Data source metadata caching
- Plugin metadata caching
- User session caching

### Request Optimization
- Request queue management (max 5 parallel data source requests)
- Request cancellation for obsolete queries
- HTTP/2 support for parallel requests
- Query result streaming for large datasets

## Observability

### Metrics
- Prometheus metrics endpoint (`/metrics`)
- Query performance metrics
- Plugin execution metrics
- HTTP request metrics

### Logging
- Structured logging throughout application
- Configurable log levels per component
- Log aggregation support

### Tracing
- OpenTelemetry integration
- Distributed tracing for queries
- Plugin execution tracing

## Extensibility Points

1. **Plugin System** - Add custom data sources, panels, and apps
2. **Provisioning** - Automate configuration
3. **Webhooks** - Alert notifications
4. **HTTP API** - External integrations
5. **Expression Engine** - Custom query transformations
6. **Theme System** - Custom styling

## Key Design Principles

1. **Plugin-first architecture** - Core features as plugins
2. **Separation of concerns** - Clear backend/frontend boundaries
3. **Service-oriented** - Modular, composable services
4. **Convention over configuration** - Sensible defaults
5. **Backward compatibility** - Dashboard migrations and versioning
6. **Performance** - Lazy loading, caching, request optimization
7. **Security** - RBAC, secrets management, sandboxed plugins

## Future Directions

- Kubernetes-native architecture with unified storage
- Enhanced plugin capabilities
- Improved real-time collaboration
- Advanced ML-based analytics
- Multi-tenancy improvements
