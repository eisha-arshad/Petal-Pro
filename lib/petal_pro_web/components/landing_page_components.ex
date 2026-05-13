defmodule PetalProWeb.LandingPageComponents do
  @moduledoc """
  A set of components for use in a landing page.
  """
  use Phoenix.Component
  use PetalComponents

  alias PetalProWeb.BillingComponents

  attr :image_src_light, :string, required: true
  attr :image_src_dark, :string, required: true
  attr :logo_cloud_title, :string, default: nil
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  slot :title
  slot :description
  slot :cloud_logo
  slot :action_buttons

  def hero(assigns) do
    ~H"""
    <section id="hero" class="overflow-hidden bg-white dark:bg-gray-950">
      <.particles_animation quantity={30} class="fade-in-animation" />
      <.container max_width={@max_width} class="stagger-fade-in-animation relative z-10 xl:pt-32">
        <div
          class="fade-in-animation left-[calc(50%-4rem)] absolute top-10 -z-10 transform-gpu blur-3xl sm:left-[calc(50%-18rem)] lg:-left-[calc(10%-5rem)] lg:top-[calc(50%-28rem)] xl:top-[calc(50%-26rem)] xl:left-[calc(50%-22rem)]"
          aria-hidden="true"
        >
          <div
            class="aspect-[1108/632] w-[69rem] from-primary-300 to-primary-500 bg-gradient-to-r opacity-25"
            style="clip-path: polygon(25.9% 0%, 200% 25%, 60% 100%, 5% 75%)"
          >
          </div>
        </div>
        <div class="-mx-3 flex flex-wrap items-center overflow-hidden">
          <div class="w-full gap-4 px-3 xl:w-1/3">
            <div class="py-12">
              <div class="mx-auto mb-8 max-w-lg text-center lg:max-w-md lg:text-left xl:mx-0">
                <.h1 class="fade-in-animation font-bold leading-tight">
                  {render_slot(@title)}
                </.h1>

                <p class="fade-in-animation mt-8 text-lg leading-relaxed text-gray-500 dark:text-gray-400">
                  {render_slot(@description)}
                </p>
              </div>
              <div class="fade-in-animation mt-12 space-x-2 text-center xl:text-left">
                {render_slot(@action_buttons)}
              </div>
            </div>
          </div>
          <div class="mb-12 w-full px-3 lg:mb-0 xl:w-2/3 xl:pl-16">
            <div class="flex items-center justify-center lg:h-128">
              <img
                id="hero-image-light"
                class="fade-in-from-right-animation w-[76rem] rounded-md bg-gray-200 ring-1 ring-gray-200 dark:hidden"
                src={@image_src_light}
                alt="Hero image light"
              />
              <img
                id="hero-image-dark"
                class="fade-in-from-right-animation w-[76rem] bg-white/5 ring-white/10 hidden rounded-md ring-1 dark:block"
                src={@image_src_dark}
                alt="Hero image dark"
              />
            </div>
          </div>
        </div>

        <%= if length(@cloud_logo) > 0 do %>
          <div class="mt-40">
            <.logo_cloud title={@logo_cloud_title} cloud_logo={@cloud_logo} />
          </div>
        <% end %>
      </.container>
    </section>
    """
  end

  attr :title, :string
  attr :cloud_logo, :list, default: [], doc: "List of slots"

  def logo_cloud(assigns) do
    ~H"""
    <div id="logo-cloud" class="container mx-auto px-4">
      <%= if @title do %>
        <h2 class="fade-in-animation mb-10 text-center text-2xl text-gray-500 dark:text-gray-300">
          {@title}
        </h2>
      <% end %>

      <div class="flex flex-wrap justify-center">
        <%= for logo <- @cloud_logo do %>
          <div class="w-full p-4 md:w-1/3 lg:w-1/6">
            <div class="py-4 lg:py-8">
              {render_slot(logo)}
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string
  attr :id, :string, default: nil

  attr :features, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (heroicon class), :title and :description"

  attr :grid_classes, :string,
    default: "grid-cols-1 lg:grid-cols-3 md:grid-cols-2",
    doc: "Tailwind grid cols class to specify how many columns you want"

  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]

  def features(assigns) do
    ~H"""
    <section
      id="features"
      class="relative z-10 mt-24 overflow-hidden bg-white py-16 text-center dark:bg-gray-950 dark:text-white md:pt-16 md:pb-32"
    >
      <.container max_width={@max_width} class="stagger-fade-in-animation relative z-10">
        <.particles_animation class="fade-in-animation" />
        <div class="mx-auto mb-16 md:mb-20 lg:w-7/12">
          <div class="fade-in-animation mb-5 bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-3xl font-bold leading-tight tracking-tight text-transparent dark:from-white/5 dark:via-gray-300 dark:to-white sm:leading-tight md:mb-7 md:text-5xl lg:leading-relaxed">
            {@title}
          </div>
          <div class="fade-in-animation text-lg font-light leading-relaxed text-gray-500 dark:text-gray-400 md:text-2xl">
            {@description}
          </div>
        </div>

        <div
          class={["fade-in-animation group grid place-items-center gap-8", @grid_classes]}
          data-highlighter
        >
          <%= for feature <- @features do %>
            <div
              id={feature.id}
              class="fade-in-animation shadow-3xl relative flex h-full flex-col justify-between overflow-hidden rounded-3xl bg-gray-200 p-px before:translate-x-[var(--mouse-x)] before:translate-y-[var(--mouse-y)] before:blur-[100px] before:pointer-events-none before:absolute before:-top-48 before:-left-48 before:z-30 before:h-96 before:w-96 before:rounded-full before:opacity-0 before:transition-opacity before:duration-500 after:rounded-[inherit] after:[background:_radial-gradient(250px_circle_at_var(--mouse-x)_var(--mouse-y),theme(colors.gray.400),transparent)] after:absolute after:inset-0 after:z-10 after:opacity-0 after:transition-opacity after:duration-500 hover:before:opacity-20 group-hover:after:opacity-100 dark:bg-gray-800 dark:before:bg-primary-500"
            >
              <div class="rounded-[inherit] relative z-20 flex h-full flex-col justify-between overflow-hidden bg-gray-50 dark:bg-gray-950/90">
                <div class="flex h-full flex-col items-center justify-between p-12">
                  <div class="mb-4 flex justify-center md:mb-6">
                    <div class="[background:linear-gradient(theme(colors.gray.50),_theme(colors.gray.50))_padding-box,_conic-gradient(theme(colors.gray.200),_theme(colors.gray.100)_25%,_theme(colors.gray.100)_75%,_theme(colors.gray.200)_100%)_border-box] relative flex h-16 w-16 items-center justify-center rounded-2xl border border-transparent shadow-2xl before:absolute before:inset-0 before:rounded-2xl dark:[background:linear-gradient(theme(colors.gray.900),_theme(colors.gray.900))_padding-box,_conic-gradient(theme(colors.gray.400),_theme(colors.gray.700)_25%,_theme(colors.gray.700)_75%,_theme(colors.gray.400)_100%)_border-box] dark:before:bg-gray-800/30">
                      <.icon
                        name={feature.icon}
                        class="relative h-6 w-6 text-gray-900 dark:text-gray-200"
                      />
                    </div>
                  </div>
                  <!-- Text -->
                  <div class="pt-0 md:pt-2">
                    <div class="mb-5">
                      <div>
                        <h3 class="via-gray-700/80 inline-flex bg-gradient-to-r from-gray-900 to-gray-900 bg-clip-text pb-2 text-xl font-bold text-transparent dark:from-gray-200/60 dark:to-gray-200/60 dark:via-gray-200">
                          {feature.title}
                        </h3>
                        <p class="leading-normal text-gray-600 dark:text-gray-400">
                          {feature.description}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div>
                    <a
                      class="relative text-gray-500 transition duration-150 ease-in-out before:pointer-events-none before:absolute before:inset-0 before:rounded-full hover:text-gray-400 dark:text-gray-300 dark:before:bg-gray-800/30 dark:hover:text-white"
                      href="#0"
                    >
                      <span class="relative inline-flex items-center">
                        Learn more
                        <.icon
                          name="hero-arrow-right-mini"
                          class="text-primary-600 ml-1 h-4 w-4 transition-transform duration-150 ease-in-out group-hover:translate-x-0.5 dark:text-primary-500"
                        />
                      </span>
                    </a>
                  </div>
                </div>
              </div>
            </div>

            <%!-- <div class="px-8 mb-10 border-gray-200 md:px-16 fade-in-animation last:border-0">
              <div class="flex justify-center mb-4 md:mb-6">
                <span class="flex items-center justify-center w-12 h-12 rounded-md bg-primary-600">
                  <.icon name={feature.icon} class="w-6 h-6 text-white" />
                </span>
              </div>
              <div class="mb-2 text-lg font-medium md:text-2xl">
                <%= feature.title %>
              </div>
              <p class="font-light leading-normal md:text-lg">
                <%= feature.description %>
              </p>
            </div> --%>
          <% end %>
        </div>
      </.container>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :image_src_light, :string, required: true
  attr :image_src_dark, :string, required: true
  attr :inverted, :boolean, default: false
  attr :blur_color, :any, default: "primary", values: ["primary", "secondary", false]
  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]
  attr :icon, :string, default: nil
  slot :inner_block

  def solo_feature(assigns) do
    ~H"""
    <section
      id="benefits"
      class="relative z-10 overflow-hidden bg-white py-16 dark:bg-gray-950 dark:text-white md:pt-24 md:pb-40"
      data-offset="false"
    >
      <.container max_width={@max_width} class="stagger-fade-in-animation relative z-10">
        <.particles_animation class="fade-in-animation" />

        <div class={"#{if @inverted, do: "flex-row-reverse", else: ""} relative isolate flex flex-wrap items-center gap-20 px-6 py-32 sm:px-10 sm:py-24 md:flex-nowrap lg:px-0 lg:py-24"}>
          <div class="fade-in-animation md:w-1/3">
            <div class="from-primary-600/50 via-primary-600 to-primary-400 shadow-primary-400/50 mb-4 flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-gradient-to-tr shadow-lg ring ring-white dark:from-primary-600/50 dark:via-primary-800 dark:to-primary-400 dark:highlight-white/10 dark:ring-primary-400/80">
              <.icon name={@icon} class="text-primary-200 h-8 w-8" />
            </div>
            <div class="fade-in-animation mb-5 bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-3xl font-bold leading-tight tracking-tight text-transparent dark:from-white/50 dark:via-gray-300 dark:to-white sm:leading-tight md:mb-7 md:text-5xl lg:leading-relaxed">
              {@title}
            </div>

            <div class="space-y-4 text-lg md:space-y-5 md:text-xl">
              <p class="fade-in-animation mt-8 leading-relaxed text-gray-500 dark:text-gray-400">
                {@description}
              </p>
            </div>
            <%= if render_slot(@inner_block) do %>
              <div class="fade-in-animation">
                {render_slot(@inner_block)}
              </div>
            <% end %>
          </div>
          <div
            :if={@blur_color}
            class={"#{if @inverted, do: "-z-10 -translate-y-1/2 rotate-180 md:-top-1/8 lg:top-auto lg:right-1/3 lg:bottom-0 lg:translate-y-0", else: "top-72 -left-1/4 -z-10 -translate-y-1/2 md:-left-1/6 md:top-0 lg:top-20 lg:bottom-auto lg:left-1/3 lg:translate-y-0"} fade-in-animation pointer-events-none absolute transform-gpu overflow-hidden blur-3xl"}
            aria-hidden="true"
          >
            <div
              class={"#{if @blur_color == "primary", do: "from-primary-200 to-primary-600 bg-primary-animation"} #{if @blur_color == "secondary", do: "from-secondary-200 to-secondary-600 bg-secondary-animation"} aspect-[1155/678] w-[72.1875rem] relative flex items-center justify-center bg-gradient-to-tr opacity-25"}
              style={"#{if @inverted, do: "clip-path: polygon(25.9% 0%, 100% 25%, 60% 100%, 5% 75%)", else: "clip-path: polygon(25.9% 0%, 100% 0%, 50% 100%, 0% 50%)"}"}
            >
            </div>
          </div>
          <div class="w-full md:mt-0 lg:w-2/3">
            <img
              class="bg-white/5 ring-white/10 fade-in-animation z-10 w-full rounded-md shadow-2xl ring-1 dark:hidden"
              src={@image_src_light}
              alt="Screenshot Light"
            />
            <img
              class="bg-white/5 ring-white/10 fade-in-animation z-10 hidden w-full rounded-md shadow-2xl ring-1 dark:block"
              src={@image_src_dark}
              alt="Screenshot Dark"
            />
          </div>
        </div>
      </.container>
    </section>
    """
  end

  attr :title, :string, default: "Testimonials"
  attr :testimonials, :list, doc: "A list of maps with the keys: content, image_src, name, title"
  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]

  def testimonials(assigns) do
    ~H"""
    <section
      id="testimonials"
      class="stagger-fade-in-animation relative z-10 bg-white dark:bg-gray-950"
    >
      <div class="content-wrapper relative isolate overflow-hidden py-36">
        <!-- Blur Gradient -->
        <div class="fade-in-animation pointer-events-none absolute top-10 left-1/3 -z-10 -translate-y-1/2 transform-gpu overflow-hidden blur-3xl lg:top-20 lg:bottom-auto lg:translate-y-0">
          <div
            class="from-primary-200 to-primary-600 bg-primary-animation aspect-[1155/678] w-[72.1875rem] relative flex items-center justify-center bg-gradient-to-tr opacity-25"
            style="clip-path: polygon(55.9% 10%, 20% 0%, 50% 70%, 0% 50%)"
          >
          </div>
        </div>
        <.particles_animation class="fade-in-animation" />
        <div class="section-header mb-5 text-center md:mb-12">
          <div class="fade-in-animation mb-5 bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-3xl font-bold leading-tight tracking-tight text-transparent dark:from-white/5 dark:via-gray-300 dark:to-white sm:leading-tight md:mb-7 md:text-5xl lg:leading-relaxed">
            {@title}
          </div>
        </div>
        <.container max_width={@max_width} class="relative z-10">
          <div class="relative isolate before:to-20% before:absolute before:inset-0 before:z-20 before:-translate-x-full before:bg-gradient-to-l before:from-transparent before:to-white after:to-20% after:absolute after:inset-0 after:z-20 after:translate-x-full after:bg-gradient-to-r after:from-transparent after:to-white dark:before:to-gray-950 dark:after:to-gray-950">
            <div class="solo-animation fade-in-animation flickity group">
              <div data-highlighter>
                <%= for testimonial <- @testimonials do %>
                  <.testimonial_panel {testimonial} />
                <% end %>
              </div>
            </div>
          </div>
        </.container>
      </div>
    </section>

    <script phx-update="ignore" id="testimonials-js" type="module">
      // Flickity allows for a touch-enabled slideshow - used for testimonials
      import flickity from 'https://cdn.skypack.dev/flickity@2';

      let el = document.querySelector(".flickity");

      if(el){
        new flickity(el, {
          cellAlign: "left",
          prevNextButtons: false,
          adaptiveHeight: false,
          cellSelector: ".carousel-cell",
        });
      }
    </script>

    <link
      rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.min.css"
      integrity="sha512-B0mpFwHOmRf8OK4U2MBOhv9W1nbPw/i3W1nBERvMZaTWd3+j+blGbOyv3w1vJgcy3cYhzwgw1ny+TzWICN35Xg=="
      crossorigin="anonymous"
      referrerpolicy="no-referrer"
    />
    <style>
      /* Modify the testimonial slider to go off the page */
      #testimonials .flickity-viewport {
        overflow: unset;
      }

      #testimonials .flickity-page-dots {
        position: relative;
        bottom: unset;
        margin-top: 40px;
        text-align: center;
      }

      #testimonials .flickity-page-dots .dot {
        background: #3b82f6;
        transition: 0.3s all ease;
        opacity: 0.2;
        margin: 0;
        margin-right: 10px;
      }

      #testimonials .flickity-page-dots .dot.is-selected {
        opacity: 0.8;
      }

      .dark #testimonials .flickity-page-dots .dot {
        background: white;
      }
    </style>
    """
  end

  attr :content, :string, required: true
  attr :image_src, :string, required: true
  attr :name, :string, required: true
  attr :title, :string, required: true

  def testimonial_panel(assigns) do
    ~H"""
    <div class="fade-in-animation bg-primary-50 carousel-cell relative mr-10 w-full overflow-hidden rounded-3xl text-gray-700 shadow-lg before:translate-x-[var(--mouse-x)] before:translate-y-[var(--mouse-y)] before:blur-[100px] before:pointer-events-none before:absolute before:-top-48 before:-left-48 before:z-30 before:h-96 before:w-96 before:rounded-full before:opacity-0 before:transition-opacity before:duration-500 after:rounded-[inherit] after:[background:_radial-gradient(250px_circle_at_var(--mouse-x)_var(--mouse-y),theme(colors.gray.400),transparent)] after:absolute after:inset-0 after:z-10 after:opacity-0 after:transition-opacity after:duration-500 last:mr-0 hover:before:opacity-20 group-hover:after:opacity-100 dark:shadow-3xl dark:bg-gray-800 dark:text-white dark:before:bg-primary-500 md:w-8/12 lg:w-5/12">
      <div class="rounded-[inherit] relative z-20 flex h-full flex-col justify-between overflow-hidden bg-gray-50 p-6 dark:bg-gray-900 md:p-8">
        <blockquote class="mt-6 md:flex md:grow md:flex-col">
          <div class="relative text-lg font-medium md:grow">
            <svg
              class="top-[-20px] text-primary-500 absolute left-0 h-8 w-8 -translate-x-3 -translate-y-2 transform opacity-40"
              fill="currentColor"
              viewBox="0 0 32 32"
              aria-hidden="true"
            >
              <path d="M9.352 4C4.456 7.456 1 13.12 1 19.36c0 5.088 3.072 8.064 6.624 8.064 3.36 0 5.856-2.688 5.856-5.856 0-3.168-2.208-5.472-5.088-5.472-.576 0-1.344.096-1.536.192.48-3.264 3.552-7.104 6.624-9.024L9.352 4zm16.512 0c-4.8 3.456-8.256 9.12-8.256 15.36 0 5.088 3.072 8.064 6.624 8.064 3.264 0 5.856-2.688 5.856-5.856 0-3.168-2.304-5.472-5.184-5.472-.576 0-1.248.096-1.44.192.48-3.264 3.456-7.104 6.528-9.024L25.864 4z">
              </path>
            </svg>
            <p class="relative font-light leading-relaxed text-gray-500 dark:text-gray-400">
              {@content}
            </p>
          </div>
          <footer class="mt-8">
            <div class="flex items-start">
              <div class="inline-flex shrink-0 rounded-full border-2 border-white">
                <img class="h-12 w-12 rounded-full" src={@image_src} alt="" />
              </div>
              <div class="ml-4">
                <div class="text-base font-semibold text-gray-900 dark:text-gray-100">
                  {@name}
                </div>
                <div class="text-base font-normal text-gray-700 dark:text-gray-300">
                  {@title}
                </div>
              </div>
            </div>
          </footer>
        </blockquote>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]
  attr :products, :map, default: PetalPro.Billing.Plans.products()
  attr :button_label, :string, default: "Sign up now"

  def pricing(assigns) do
    ~H"""
    <section
      id="pricing"
      class="stagger-fade-in-animation relative overflow-hidden py-24 text-gray-700 dark:text-white md:py-32"
    >
      <.particles_animation class="fade-in-animation z-99" />
      <.container max_width={@max_width}>
        <div class="mx-auto mb-16 text-center md:mb-20 lg:w-7/12 ">
          <div class="fade-in-animation mb-5 bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-3xl font-bold leading-tight tracking-tight text-transparent dark:from-white/5 dark:via-gray-300 dark:to-white sm:leading-tight md:mb-7 md:text-5xl lg:leading-relaxed">
            {@title}
          </div>
          <div class="fade-in-animation text-lg font-light leading-relaxed text-gray-500 dark:text-gray-400 md:text-2xl">
            {@description}
          </div>
        </div>

        <div class="fade-in-animation pb-32">
          <div class="relative -z-50 hidden w-full max-w-xs dark:block md:max-w-5xl xl:max-w-7xl">
            <div class="top-[5rem] bg-primary-400 w-[30rem] h-[30rem] animate-blob absolute rounded-full opacity-10 mix-blend-lighten blur-3xl filter lg:top-0 lg:-left-4">
            </div>
            <div class="top-[40rem] bg-primary-600 w-[40rem] h-[40rem] animate-blob animation-delay-1000 absolute rounded-full opacity-10 mix-blend-lighten blur-3xl filter lg:top-4 lg:left-32">
            </div>
            <div class="bg-primary-500 top-[60rem] w-[30rem] h-[30rem] animate-blob animation-delay-2000 absolute rounded-full opacity-10 mix-blend-lighten blur-3xl filter lg:top-16 lg:-right-4">
            </div>
            <div class="bg-secondary-600 top-[10rem] right-[5rem] w-[40rem] h-[40rem] animate-blob animation-delay-3000 absolute rounded-full opacity-10 mix-blend-lighten blur-3xl filter lg:top-12 lg:right-56">
            </div>
            <div class="bg-secondary-500 top-[80rem] w-[25rem] h-[25rem] animate-blob animation-delay-4000 absolute rounded-full opacity-10 mix-blend-lighten blur-3xl filter lg:top-8 lg:left-96">
            </div>
          </div>

          <BillingComponents.pricing_panels_container panels={length(@products)} interval_selector>
            <%= for product <- @products do %>
              <BillingComponents.pricing_panel
                label={product.name}
                description={product.description}
                features={product.features}
                most_popular={Map.get(product, :most_popular)}
                class="fade-in-animation"
              >
                <%= for plan <- product.plans do %>
                  <BillingComponents.item_price
                    id={"pricing-plan-#{plan.id}"}
                    interval={plan.interval}
                    amount={plan[:amount]}
                    button_label={@button_label}
                    is_public
                  />
                <% end %>
              </BillingComponents.pricing_panel>
            <% end %>
          </BillingComponents.pricing_panels_container>
        </div>
      </.container>
    </section>
    """
  end

  attr :quantity, :integer, default: 25
  attr :class, :string, default: nil

  def particles_animation(assigns) do
    ~H"""
    <div class={["absolute inset-0 mx-auto", @class]}>
      <div class="absolute inset-0 -z-10" aria-hidden="true">
        <canvas data-particle-animation data-particle-quantity={@quantity}></canvas>
      </div>
    </div>
    """
  end

  def load_js_animations(assigns) do
    ~H"""
    <script type="module">
      // Use GSAP for animations
      // https://greensock.com/gsap/
      import gsap from 'https://cdn.skypack.dev/gsap@3.10.4';

      // Put it on the window for when you want to try out animations in the console
      window.gsap = gsap;

      // A plugin for GSAP that detects when an element enters the viewport - this helps with timing the animation
      import ScrollTrigger from "https://cdn.skypack.dev/gsap@3.10.4/ScrollTrigger";
      gsap.registerPlugin(ScrollTrigger);

      animateHero();
      setupPageAnimations();

      // This is needed to ensure the animations timings are correct as you scroll
      setTimeout(() => {
        ScrollTrigger.refresh(true);
      }, 1000);

      function animateHero() {

        // A timeline just means you can chain animations together - one after another
        // https://greensock.com/docs/v3/GSAP/gsap.timeline()
        const heroTimeline = gsap.timeline({});

        heroTimeline
          .to("#hero .fade-in-animation", {
            opacity: 1,
            y: 0,
            stagger: 0.1,
            ease: "power2.out",
            duration: 1,
          })
          .to("#hero-image-light", {
            opacity: 1,
            x: 0,
            duration: 0.4
          }, ">-1.3")
          .to("#hero-image-dark", {
            opacity: 1,
            x: 0,
            duration: 0.4
          }, ">-1.3")
          .to("#logo-cloud .fade-in-animation", {
            opacity: 1,
            y: 0,
            stagger: 0.1,
            ease: "power2.out",
          })
      }

      function setupPageAnimations() {

        // This allows us to give any individual HTML element the class "solo-animation"
        // and that element will fade in when scrolled into view
        gsap.utils.toArray(".solo-animation").forEach((item) => {
          gsap.to(item, {
            y: 0,
            opacity: 1,
            duration: 0.5,
            ease: "power2.out",
            scrollTrigger: {
              trigger: item,
            },
          });
        });

        // Add the class "stagger-fade-in-animation" to a parent element, then all elements within it
        // with the class "fade-in-animation" will fade in on scroll in a staggered formation to look
        // more natural than them all fading in at once
        gsap.utils.toArray(".stagger-fade-in-animation").forEach((stagger) => {
          const children = stagger.querySelectorAll(".fade-in-animation");
          gsap.to(children, {
            opacity: 1,
            y: 0,
            ease: "power2.out",
            stagger: 0.15,
            duration: 0.5,
            scrollTrigger: {
              trigger: stagger,
              start: "top 75%",
            },
          });
        });
      }
    </script>
    """
  end
end
