module Modal.MappingBuilder exposing (ExternalMsg(..), Model, Msg(..), empty, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Modal as Modal
import Bootstrap.Utilities.Display as Display
import Html exposing (Html, text)
import Html.Attributes exposing (for, selected, value)
import Types.InterfaceMapping as InterfaceMapping exposing (InterfaceMapping)
import Types.SuggestionPopup as SuggestionPopup exposing (SuggestionPopup)


type alias Model =
    { interfaceMapping : InterfaceMapping
    , editMode : Bool
    , interfaceTypeProperties : Bool
    , interfaceAggregationObject : Bool
    , endpointWarningPopup : SuggestionPopup
    , visibility : Modal.Visibility
    }


type InterfaceNameStatus
    = InvalidEndpoint
    | DeprecatedEndpoint
    | GoodEndpoint


empty : Model
empty =
    { interfaceMapping = InterfaceMapping.empty
    , editMode = False
    , interfaceTypeProperties = True
    , interfaceAggregationObject = False
    , endpointWarningPopup = SuggestionPopup.new ""
    , visibility = Modal.hidden
    }


init : InterfaceMapping -> Bool -> Bool -> Bool -> Bool -> Model
init interfaceMapping editMode isProperties isObject shown =
    { interfaceMapping = interfaceMapping
    , editMode = editMode
    , interfaceTypeProperties = isProperties
    , interfaceAggregationObject = isObject
    , endpointWarningPopup =
        SuggestionPopup.new "Endpoints of depth 1 in Object aggregate interfaces are deprecated. The endpoint should have depth level of 2 or more (e.g. /my/endpoint)."
    , visibility =
        if shown then
            Modal.shown

        else
            Modal.hidden
    }


type ModalResult
    = ModalCancel
    | ModalOk


type Msg
    = Close ModalResult
      -- mapping messages
    | UpdateMappingEndpoint String
    | UpdateMappingType String
    | UpdateMappingReliability String
    | UpdateMappingRetention String
    | UpdateMappingExpiry String
    | UpdateMappingDatabaseRetention String
    | UpdateMappingTTL String
    | UpdateMappingAllowUnset Bool
    | UpdateMappingTimestamp Bool
    | UpdateMappingDescription String
    | UpdateMappingDoc String
      -- SuggestionPopup
    | SuggestionPopupMsg SuggestionPopup.Msg


type ExternalMsg
    = Noop
    | AddNewMapping InterfaceMapping
    | EditMapping InterfaceMapping


update : Msg -> Model -> ( Model, ExternalMsg )
update message model =
    case message of
        Close ModalCancel ->
            ( { model | visibility = Modal.hidden }
            , Noop
            )

        Close ModalOk ->
            ( { model | visibility = Modal.hidden }
            , if model.editMode then
                EditMapping model.interfaceMapping

              else
                AddNewMapping model.interfaceMapping
            )

        UpdateMappingEndpoint newEndpoint ->
            ( { model | interfaceMapping = InterfaceMapping.setEndpoint newEndpoint model.interfaceMapping }
            , Noop
            )

        UpdateMappingType newType ->
            case InterfaceMapping.stringToMappingType newType of
                Ok mappingType ->
                    ( { model | interfaceMapping = InterfaceMapping.setType mappingType model.interfaceMapping }
                    , Noop
                    )

                Err _ ->
                    ( model
                    , Noop
                    )

        UpdateMappingReliability newReliability ->
            case InterfaceMapping.stringToReliability newReliability of
                Ok reliability ->
                    ( { model
                        | interfaceMapping =
                            InterfaceMapping.setReliability reliability model.interfaceMapping
                      }
                    , Noop
                    )

                Err _ ->
                    ( model
                    , Noop
                    )

        UpdateMappingRetention newMapRetention ->
            case InterfaceMapping.stringToRetention newMapRetention of
                Ok InterfaceMapping.Discard ->
                    ( { model
                        | interfaceMapping =
                            model.interfaceMapping
                                |> InterfaceMapping.setRetention InterfaceMapping.Discard
                                |> InterfaceMapping.setExpiry 0
                      }
                    , Noop
                    )

                Ok retention ->
                    ( { model
                        | interfaceMapping =
                            InterfaceMapping.setRetention retention model.interfaceMapping
                      }
                    , Noop
                    )

                Err _ ->
                    ( model
                    , Noop
                    )

        UpdateMappingExpiry newMappingExpiry ->
            let
                expiry =
                  newMappingExpiry
                  |> String.toInt
                  |> Maybe.withDefault 0
                  |> max 0
            in
            ( { model | interfaceMapping = InterfaceMapping.setExpiry expiry model.interfaceMapping }
            , Noop
            )

        UpdateMappingDatabaseRetention newDatabaseRetention ->
            case InterfaceMapping.stringToDatabaseRetention newDatabaseRetention of
                Ok databaseRetention ->
                    ( { model
                        | interfaceMapping =
                            InterfaceMapping.setDatabaseRetention databaseRetention model.interfaceMapping
                      }
                    , Noop
                    )

                Err _ ->
                    ( model
                    , Noop
                    )

        UpdateMappingTTL stringTTL ->
            let
                ttl =
                  stringTTL
                  |> String.toInt
                  |> Maybe.withDefault 0
                  |> max 0
            in
            ( { model | interfaceMapping = InterfaceMapping.setTTL ttl model.interfaceMapping }
            , Noop
            )

        UpdateMappingAllowUnset allowUnset ->
            ( { model | interfaceMapping = InterfaceMapping.setAllowUnset allowUnset model.interfaceMapping }
            , Noop
            )

        UpdateMappingTimestamp timestamp ->
            ( { model | interfaceMapping = InterfaceMapping.setExplicitTimestamp timestamp model.interfaceMapping }
            , Noop
            )

        UpdateMappingDescription newDescription ->
            ( { model | interfaceMapping = InterfaceMapping.setDescription newDescription model.interfaceMapping }
            , Noop
            )

        UpdateMappingDoc newDoc ->
            ( { model | interfaceMapping = InterfaceMapping.setDoc newDoc model.interfaceMapping }
            , Noop
            )

        SuggestionPopupMsg msg ->
            ( { model
                | endpointWarningPopup =
                    SuggestionPopup.update model.endpointWarningPopup msg
              }
            , Noop
            )


view : Model -> Html Msg
view model =
    Modal.config (Close ModalCancel)
        |> Modal.large
        |> Modal.scrollableBody True
        |> Modal.h5 []
            [ if model.editMode then
                text "Edit mapping"

              else
                text "Add new mapping"
            ]
        |> Modal.body []
            [ renderBody
                model.interfaceMapping
                model.interfaceTypeProperties
                model.interfaceAggregationObject
                model.editMode
                model.endpointWarningPopup
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.secondary
                , Button.onClick <| Close ModalCancel
                ]
                [ text "Cancel" ]
            , Button.button
                [ Button.primary
                , Button.disabled <| not (InterfaceMapping.isValid model.interfaceMapping)
                , Button.onClick <| Close ModalOk
                ]
                [ text "Confirm" ]
            ]
        |> Modal.view model.visibility


renderBody : InterfaceMapping -> Bool -> Bool -> Bool -> SuggestionPopup -> Html Msg
renderBody mapping isProperties isObject editMode endpointWarningPopup =
    Form.form []
        [ Form.row []
            [ Form.col [ Col.sm12 ]
                [ renderMappingEndpointInput mapping.endpoint isObject editMode endpointWarningPopup ]
            ]
        , Form.row []
            [ Form.col
                [ if isProperties then
                    Col.sm8

                  else
                    Col.sm12
                ]
                [ Form.group []
                    [ Form.label [ for "mappingTypes" ] [ text "Type" ]
                    , Select.select
                        [ Select.id "mappingTypes"
                        , Select.onChange UpdateMappingType
                        ]
                        (List.map (\t -> renderMappingTypeItem (t == mapping.mType) t) InterfaceMapping.mappingTypeList)
                    ]
                ]
            , Form.col
                [ if isProperties then
                    Col.sm4

                  else
                    Col.attrs [ Display.none ]
                ]
                [ Form.group []
                    [ Form.label [ for "mappingAllowUnset" ] [ text "Options" ]
                    , Checkbox.checkbox
                        [ Checkbox.id "mappingAllowUnset"
                        , Checkbox.checked mapping.allowUnset
                        , Checkbox.onCheck UpdateMappingAllowUnset
                        ]
                        "Allow unset"
                    ]
                ]
            ]
        , Form.row
            (if isProperties || isObject then
                [ Row.attrs [ Display.none ] ]

             else
                []
            )
            [ Form.col [ Col.sm4 ]
                [ Form.group []
                    [ Form.label [ for "mappingReliability" ] [ text "Reliability" ]
                    , Select.select
                        [ Select.id "mappingReliability"
                        , Select.onChange UpdateMappingReliability
                        ]
                        [ Select.item
                            [ value "unreliable"
                            , selected <| mapping.reliability == InterfaceMapping.Unreliable
                            ]
                            [ text "Unreliable" ]
                        , Select.item
                            [ value "guaranteed"
                            , selected <| mapping.reliability == InterfaceMapping.Guaranteed
                            ]
                            [ text "Guaranteed" ]
                        , Select.item
                            [ value "unique"
                            , selected <| mapping.reliability == InterfaceMapping.Unique
                            ]
                            [ text "Unique" ]
                        ]
                    ]
                ]
            , Form.col
                [ if mapping.retention == InterfaceMapping.Discard then
                    Col.sm8

                  else
                    Col.sm4
                ]
                [ Form.group []
                    [ Form.label [ for "mappingRetention" ] [ text "Retention" ]
                    , Select.select
                        [ Select.id "mappingRetention"
                        , Select.onChange UpdateMappingRetention
                        ]
                        [ Select.item
                            [ value "discard"
                            , selected <| mapping.retention == InterfaceMapping.Discard
                            ]
                            [ text "Discard" ]
                        , Select.item
                            [ value "volatile"
                            , selected <| mapping.retention == InterfaceMapping.Volatile
                            ]
                            [ text "Volatile" ]
                        , Select.item
                            [ value "stored"
                            , selected <| mapping.retention == InterfaceMapping.Stored
                            ]
                            [ text "Stored" ]
                        ]
                    ]
                ]
            , Form.col
                [ if mapping.retention == InterfaceMapping.Discard then
                    Col.attrs [ Display.none ]

                  else
                    Col.sm4
                ]
                [ Form.group []
                    [ Form.label [ for "mappingExpiry" ] [ text "Expiry" ]
                    , InputGroup.number
                        [ Input.id "mappingExpiry"
                        , Input.value <| String.fromInt mapping.expiry
                        , Input.onInput UpdateMappingExpiry
                        ]
                        |> InputGroup.config
                        |> InputGroup.successors
                            [ InputGroup.span [] [ text "s" ] ]
                        |> InputGroup.view
                    ]
                ]
            , Form.col
                [ if mapping.databaseRetention == InterfaceMapping.NoTTL then
                    Col.sm12

                  else
                    Col.sm6
                ]
                [ Form.group []
                    [ Form.label [ for "mappingDatabaseRetention" ] [ text "Database retention" ]
                    , Select.select
                        [ Select.id "mappingDatabaseRetention"
                        , Select.onChange UpdateMappingDatabaseRetention
                        ]
                        [ Select.item
                            [ value "no_ttl"
                            , selected <| mapping.databaseRetention == InterfaceMapping.NoTTL
                            ]
                            [ text "No TTL" ]
                        , Select.item
                            [ value "use_ttl"
                            , selected <| mapping.databaseRetention == InterfaceMapping.UseTTL
                            ]
                            [ text "Use TTL" ]
                        ]
                    ]
                ]
            , Form.col
                [ if mapping.databaseRetention == InterfaceMapping.NoTTL then
                    Col.attrs [ Display.none ]

                  else
                    Col.sm6
                ]
                [ Form.group []
                    [ Form.label [ for "mappingTTL" ] [ text "TTL" ]
                    , InputGroup.number
                        [ Input.id "mappingTTL"
                        , Input.value <| String.fromInt mapping.ttl
                        , Input.onInput UpdateMappingTTL
                        ]
                        |> InputGroup.config
                        |> InputGroup.successors
                            [ InputGroup.span [] [ text "s" ] ]
                        |> InputGroup.view
                    ]
                ]
            , Form.col [ Col.sm3 ]
                [ Form.group []
                    [ Checkbox.checkbox
                        [ Checkbox.id "mappingExpTimestamp"
                        , Checkbox.checked mapping.explicitTimestamp
                        , Checkbox.onCheck UpdateMappingTimestamp
                        ]
                        "Explicit timestamp"
                    ]
                ]
            ]
        , Form.row []
            [ Form.col [ Col.sm12 ]
                [ Form.group []
                    [ Form.label [ for "mappingDescription" ] [ text "Description" ]
                    , Textarea.textarea
                        [ Textarea.id "mappingDescription"
                        , Textarea.rows 1
                        , Textarea.value <| mapping.description
                        , Textarea.onInput UpdateMappingDescription
                        ]
                    ]
                ]
            ]
        , Form.row []
            [ Form.col [ Col.sm12 ]
                [ Form.group []
                    [ Form.label [ for "mappingDoc" ] [ text "Documentation" ]
                    , Textarea.textarea
                        [ Textarea.id "mappingDoc"
                        , Textarea.rows 1
                        , Textarea.value <| mapping.doc
                        , Textarea.onInput UpdateMappingDoc
                        ]
                    ]
                ]
            ]
        ]


renderMappingTypeItem : Bool -> InterfaceMapping.MappingType -> Select.Item Msg
renderMappingTypeItem itemSelected mappingType =
    Select.item
        [ value <| InterfaceMapping.mappingTypeToString mappingType
        , selected itemSelected
        ]
        [ text <| InterfaceMapping.mappingTypeToEnglishString mappingType ]


renderMappingEndpointInput : String -> Bool -> Bool -> SuggestionPopup -> Html Msg
renderMappingEndpointInput endpoint isObject editMode endpointWarningPopup =
    let
        endpointStatus =
            case ( InterfaceMapping.isValidEndpoint endpoint, InterfaceMapping.isGoodEndpoint endpoint isObject ) of
                ( True, True ) ->
                    GoodEndpoint

                ( True, False ) ->
                    DeprecatedEndpoint

                ( False, _ ) ->
                    InvalidEndpoint
    in
    Form.group []
        [ Form.label [ for "mappingEndpoint" ] [ text "Endpoint" ]
        , Input.text
            [ Input.id "mappingEndpoint"
            , Input.value endpoint
            , Input.disabled editMode
            , Input.onInput UpdateMappingEndpoint
            , Input.success |> when (endpointStatus == GoodEndpoint)
            , Input.danger |> when (endpointStatus == InvalidEndpoint)
            ]
        , Html.map SuggestionPopupMsg
            (SuggestionPopup.view endpointWarningPopup <| endpointStatus == DeprecatedEndpoint)
        ]


when : Bool -> Input.Option m -> Input.Option m
when condition attribute =
    if condition then
        attribute

    else
        Input.attrs []
