@react.component
let make = (
  ~setCurrentStep,
  ~connector,
  ~setInitialValues,
  ~initialValues,
  ~isUpdateFlow,
  ~isPayoutFlow,
) => {
  open ConnectorUtils
  open APIUtils
  open PageLoaderWrapper
  open LogicUtils
  let getURL = useGetURL()
  let _showAdvancedConfiguration = false
  let mixpanelEvent = MixpanelHook.useSendEvent()
  let (paymentMethodsEnabled, setPaymentMethods) = React.useState(_ =>
    Dict.make()->JSON.Encode.object->getPaymentMethodEnabled
  )
  let (metaData, setMetaData) = React.useState(_ => Dict.make()->JSON.Encode.object)
  let showToast = ToastState.useShowToast()
  let connectorID = initialValues->getDictFromJsonObject->getOptionString("merchant_connector_id")
  let (screenState, setScreenState) = React.useState(_ => Loading)
  let updateAPIHook = useUpdateMethod(~showErrorToast=false, ())

  let updateDetails = value => {
    setPaymentMethods(_ => value->Array.copy)
  }

  let setPaymentMethodDetails = async () => {
    try {
      setScreenState(_ => Loading)
      let _ =
        initialValues->getConnectorPaymentMethodDetails(
          setPaymentMethods,
          setMetaData,
          isUpdateFlow,
          isPayoutFlow,
          connector,
          updateDetails,
        )
      setScreenState(_ => Success)
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Something went wrong")
        setScreenState(_ => PageLoaderWrapper.Error(err))
      }
    }
  }

  React.useEffect1(() => {
    setPaymentMethodDetails()->ignore
    None
  }, [connector])

  let mixpanelEventName = isUpdateFlow ? "processor_step2_onUpdate" : "processor_step2"

  let onSubmit = async () => {
    mixpanelEvent(~eventName=mixpanelEventName, ())
    try {
      setScreenState(_ => Loading)
      let obj: ConnectorTypes.wasmRequest = {
        connector,
        payment_methods_enabled: paymentMethodsEnabled,
        metadata: metaData,
      }
      let body =
        constructConnectorRequestBody(obj, initialValues)->ignoreFields(
          connectorID->Option.getOr(""),
          connectorIgnoredField,
        )
      let connectorUrl = getURL(~entityName=CONNECTOR, ~methodType=Post, ~id=connectorID, ())
      let response = await updateAPIHook(connectorUrl, body, Post, ())
      setInitialValues(_ => response)
      setScreenState(_ => Success)
      setCurrentStep(_ => ConnectorTypes.SummaryAndTest)
      showToast(
        ~message=!isUpdateFlow ? "Connector Created Successfully!" : "Details Updated!",
        ~toastType=ToastSuccess,
        (),
      )
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Something went wrong")
        let errorCode = err->safeParse->getDictFromJsonObject->getString("code", "")
        let errorMessage = err->safeParse->getDictFromJsonObject->getString("message", "")

        if errorCode === "HE_01" {
          showToast(~message="Connector label already exist!", ~toastType=ToastError, ())
          setCurrentStep(_ => ConnectorTypes.IntegFields)
        } else {
          showToast(~message=errorMessage, ~toastType=ToastError, ())
          setScreenState(_ => PageLoaderWrapper.Error(err))
        }
      }
    }
  }

  <PageLoaderWrapper screenState>
    <div className="flex flex-col">
      <div className="flex justify-between border-b p-2 md:px-10 md:py-6">
        <div className="flex gap-2 items-center">
          <GatewayIcon gateway={connector->String.toUpperCase} />
          <h2 className="text-xl font-semibold">
            {connector->getDisplayNameForConnector->React.string}
          </h2>
        </div>
        <div className="self-center">
          <Button text="Proceed" buttonType={Primary} onClick={_ => onSubmit()->ignore} />
        </div>
      </div>
      <div className="grid grid-cols-4 flex-1 p-2 md:p-10">
        <div className="flex flex-col gap-6 col-span-3">
          <h1 className="text-orange-950 bg-orange-100 border w-full p-2 rounded-md ">
            <span className="text-orange-950 font-bold text-fs-14 mx-2">
              {"NOTE:"->React.string}
            </span>
            {"Please verify if the payment methods are turned on at the processor end as well."->React.string}
          </h1>
          <PaymentMethod.PaymentMethodsRender
            _showAdvancedConfiguration
            connector
            paymentMethodsEnabled
            updateDetails
            metaData
            setMetaData
            isPayoutFlow
          />
        </div>
      </div>
    </div>
  </PageLoaderWrapper>
}
