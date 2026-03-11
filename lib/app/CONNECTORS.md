# Connector pattern

Connectors inject controllers or data into the widget tree so children can access them without prop drilling. Use the same style for new features.

- **AccountConnector** (`account/widget/connector.dart`) – provides account/auth context.
- **FollowConnector** (`follow/widget/connector.dart`) – provides follow state.
- **PostsConnector, PostsIdConnector, PostsRouteConnector, PostsControllerConnector, PostHistoryConnector, PostsControllerHistoryConnector** (`post/widget/shared/connector.dart`) – post context and history.
- **ControllerHistoryConnector, ItemHistoryConnector** (`history/widget/connector.dart`) – generic history connector; use for lists and detail screens that need to register with history.
