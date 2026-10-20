import IPhoneMockup, { IPhoneMockupProps } from "./IPhoneMockup";

export interface PhoneMockupProps extends IPhoneMockupProps {}

export default function PhoneMockup(props: PhoneMockupProps) {
  return <IPhoneMockup {...props} />;
}
