import IPhoneMockup, { IPhoneMockupProps } from "./IPhoneMockup";

export type PhoneMockupProps = IPhoneMockupProps;

export default function PhoneMockup(props: PhoneMockupProps) {
  return <IPhoneMockup {...props} />;
}
