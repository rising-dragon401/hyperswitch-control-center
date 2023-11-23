module HyperSwitchEntryComponent = {
  @react.component
  let make = () => {
    open HSLocalStorage
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let postDetails = APIUtils.useUpdateMethod()
    let email = getFromMerchantDetails("email")
    let name = getFromUserDetails("name")
    let url = RescriptReactRouter.useUrl()
    let (_zone, setZone) = React.useContext(UserTimeZoneProvider.userTimeContext)
    let setFeatureFlag = HyperswitchAtom.featureFlagAtom->Recoil.useSetRecoilState
    let featureFlagDetails =
      HyperswitchAtom.featureFlagAtom
      ->Recoil.useRecoilValueFromAtom
      ->LogicUtils.safeParse
      ->FeatureFlagUtils.featureFlagType
    React.useEffect0(() => {
      HSiwtchTimeZoneUtils.getUserTimeZone()->setZone
      None
    })

    React.useEffect2(() => {
      MixPanel.init(
        HSwitchGlobalVars.mixpanelToken,
        {
          "batch_requests": true,
          "loaded": () => {
            let mixpanelUserInfo =
              [("name", email->Js.Json.string), ("merchantName", name->Js.Json.string)]
              ->Js.Dict.fromArray
              ->Js.Json.object_

            let userId = MixPanel.getDistinctId()
            LocalStorage.setItem("deviceid", userId)
            MixPanel.identify(userId)
            MixPanel.mixpanel.people.set(. mixpanelUserInfo)
          },
        },
      )
      None
    }, (name, email))

    let setPageName = pageTitle => {
      let page = pageTitle->LogicUtils.snakeToTitle
      let title = featureFlagDetails.testLiveMode
        ? `${page} - Dashboard`
        : `${page} - Dashboard [Test]`
      DOMUtils.document.title = title
      GoogleAnalytics.send({hitType: "pageview", page})
      hyperswitchMixPanel(
        ~eventName=Some(pageTitle->HyperSwitchUtils.getMixpanelRouteName(url)),
        (),
      )
    }

    React.useEffect1(() => {
      switch url.path {
      | list{"user", "verify_email"} => "verify_email"->setPageName
      | list{"user", "set_password"} => "set_password"->setPageName
      | list{"user", "login"} => "magic_link_verify"->setPageName
      | _ =>
        switch Belt.List.head(url.path) {
        | Some(pageTitle) => pageTitle->setPageName
        | _ => ()
        }
      }
      None
    }, [url.path])

    let fetchFeatureFlags = async () => {
      try {
        let url = `${HSwitchGlobalVars.hyperSwitchFEPrefix}/config/merchant-access`
        let stringifiedResponse =
          (await postDetails(url, Js.Dict.empty()->Js.Json.object_, Post))->Js.Json.stringify
        setFeatureFlag(._ => stringifiedResponse)
      } catch {
      | Js.Exn.Error(e) => {
          let _err = Js.Exn.message(e)->Belt.Option.getWithDefault("Failed to Fetch!")
        }
      }
    }

    React.useEffect0(() => {
      fetchFeatureFlags()->ignore
      None
    })

    <div className="text-black">
      <HyperSwitchAuthWrapper>
        <GlobalProvider>
          <HyperSwitchApp />
        </GlobalProvider>
      </HyperSwitchAuthWrapper>
    </div>
  }
}

let uiConfig: UIConfig.t = HyperSwitchDefaultConfig.config
EntryPointUtils.renderDashboardApp(<HyperSwitchEntryComponent />, ~uiConfig)
