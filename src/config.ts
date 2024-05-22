import type { SocialsObject } from "./types";

export const SITE = {
  website: "https://swarom.dev",
  author: "Mufaddal Rangwala",
  desc: "Software Engineer Living in the San Francisco Bay Area, Particularly Interested in DevOps and Cloud Computing.",
  title: "Mufaddal Rangwala",
  lightAndDarkMode: true,
  postPerPage: 5,
};

export const LOGO_IMAGE = {
  enable: false,
  svg: true,
  width: 216,
  height: 46,
};

export const SOCIALS: SocialsObject = [
  {
    name: "Github",
    href: "https://github.com/Mufaddalone",
    active: true,
  },
  {
    name: "Linkedin",
    href: "https://www.linkedin.com/in/mufaddalrangwala/",
    active: true,
  },
  {
    name: "Mail",
    href: "mailto:mrangwala@scu.edu",
    active: true,
  }
];
