open HyperSwitchAuthUtils
let fieldWrapperClass = "w-full flex flex-col"
let labelClass = "!text-black !font-medium"
module EmailPasswordForm = {
  @react.component
  let make = (~setAuthType, ~isMagicLinkEnabled) => {
    <div className="flex flex-col gap-3">
      <FormRenderer.FieldRenderer field=emailField labelClass fieldWrapperClass />
      <div className="flex flex-col gap-3">
        <FormRenderer.FieldRenderer field=passwordField labelClass fieldWrapperClass />
        <UIUtils.RenderIf condition={isMagicLinkEnabled}>
          <label
            className={`not-italic text-[12px] font-semibold font-ibm-plex text-blue-800 cursor-pointer cursor-pointer`}
            onClick={_ => setAuthType(_ => HyperSwitchAuthTypes.ForgetPassword)}>
            {"Forgot Password?"->React.string}
          </label>
        </UIUtils.RenderIf>
      </div>
    </div>
  }
}

module EmailForm = {
  @react.component
  let make = () => {
    <FormRenderer.FieldRenderer field=emailField labelClass fieldWrapperClass />
  }
}

module ResetPasswordForm = {
  @react.component
  let make = () => {
    <>
      <FormRenderer.FieldRenderer field=createPasswordField labelClass fieldWrapperClass />
      <FormRenderer.FieldRenderer field=confirmPasswordField labelClass fieldWrapperClass />
    </>
  }
}

module ResendVerifyEmailForm = {
  @react.component
  let make = (~disableBtn) => {
    <div className="h-5-rem">
      <FormRenderer.FieldRenderer
        field={FormRenderer.makeFieldInfo(
          ~name="email",
          ~label="Email",
          ~customInput=InputFields.textInput(~isDisabled=disableBtn, ~autoComplete="off", ()),
          (),
        )}
        labelClass
      />
    </div>
  }
}
